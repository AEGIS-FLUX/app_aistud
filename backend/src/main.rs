use axum::{
    extract::Json,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::env;
use std::net::SocketAddr;

#[derive(Serialize)]
struct Health {
    status: &'static str,
    version: &'static str,
    timestamp: String,
}

async fn health() -> Json<Health> {
    Json(Health {
        status: "ok",
        version: "0.1.0",
        timestamp: chrono::Utc::now().to_rfc3339(),
    })
}

#[derive(Deserialize)]
struct GenerateRequest {
    prompt: String,
    mode: Option<String>,
    context: Option<String>,
}

#[derive(Serialize)]
struct GenerateResponse {
    job_id: String,
    status: String,
    code_dart: String,
    tokens_used: Option<u64>,
    error: Option<String>,
}

#[derive(Serialize)]
struct GroqMessage {
    role: String,
    content: String,
}

#[derive(Serialize)]
struct GroqRequest {
    model: String,
    messages: Vec<GroqMessage>,
    temperature: f32,
    max_tokens: u32,
}

#[derive(Deserialize)]
struct GroqChoice {
    message: GroqMessageResponse,
}

#[derive(Deserialize)]
struct GroqMessageResponse {
    content: String,
}

#[derive(Deserialize)]
struct GroqUsage {
    total_tokens: u64,
}

#[derive(Deserialize)]
struct GroqResponse {
    choices: Vec<GroqChoice>,
    usage: Option<GroqUsage>,
}

fn job_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    format!("job-{:x}", nanos)
}

async fn generate(Json(req): Json<GenerateRequest>) -> impl IntoResponse {
    let api_key = match env::var("GROQ_API_KEY") {
        Ok(k) if !k.is_empty() => k,
        _ => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(GenerateResponse {
                    job_id: job_id(),
                    status: "failed".to_string(),
                    code_dart: String::new(),
                    tokens_used: None,
                    error: Some("GROQ_API_KEY non configurée côté serveur".to_string()),
                }),
            );
        }
    };

    let system_prompt = "Tu es FlutterCraft GenUI. Tu génères UNIQUEMENT du code Dart Flutter valide. Pas de markdown, pas de ```dart, pas d'explication avant ou après. Juste le code compilable.";

    let user_content = match (req.mode.as_deref(), req.context.as_deref()) {
        (Some("patch"), Some(ctx)) => format!(
            "Code Dart à corriger :\n\n{}\n\nInstruction de correction : {}",
            ctx, req.prompt
        ),
        _ => req.prompt.clone(),
    };

    let body = GroqRequest {
       model: "openai/gpt-oss-120b".to_string(),
        messages: vec![
            GroqMessage {
                role: "system".to_string(),
                content: system_prompt.to_string(),
            },
            GroqMessage {
                role: "user".to_string(),
                content: user_content,
            },
        ],
        temperature: 0.3,
        max_tokens: 4096,
    };

    let client = reqwest::Client::new();
    let response = client
        .post("https://api.groq.com/openai/v1/chat/completions")
        .bearer_auth(&api_key)
        .json(&body)
        .send()
        .await;

    match response {
        Ok(resp) if !resp.status().is_success() => {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(GenerateResponse {
                    job_id: job_id(),
                    status: "failed".to_string(),
                    code_dart: String::new(),
                    tokens_used: None,
                    error: Some(format!("Groq {} : {}", status, text)),
                }),
            )
        }
        Ok(resp) => match resp.json::<GroqResponse>().await {
            Ok(groq) => {
                let code = groq
                    .choices
                    .first()
                    .map(|c| c.message.content.clone())
                    .unwrap_or_default();
                let tokens = groq.usage.map(|u| u.total_tokens);
                (
                    StatusCode::OK,
                    Json(GenerateResponse {
                        job_id: job_id(),
                        status: "done".to_string(),
                        code_dart: code,
                        tokens_used: tokens,
                        error: None,
                    }),
                )
            }
            Err(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(GenerateResponse {
                    job_id: job_id(),
                    status: "failed".to_string(),
                    code_dart: String::new(),
                    tokens_used: None,
                    error: Some(format!("Parse Groq : {}", e)),
                }),
            ),
        },
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(GenerateResponse {
                job_id: job_id(),
                status: "failed".to_string(),
                code_dart: String::new(),
                tokens_used: None,
                error: Some(format!("Réseau : {}", e)),
            }),
        ),
    }
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/fluttercraft/generate", post(generate));

    let port: u16 = env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("Listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
