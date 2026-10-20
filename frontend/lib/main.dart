import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterCraftIAApp());
}

class FlutterCraftIAApp extends StatelessWidget {
  const FlutterCraftIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterCraft IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        useMaterial3: true,
      ),
      home: const FlutterCraftIAScreen(),
    );
  }
}

enum _AppMode { genui, aegis }

class FlutterCraftIAScreen extends StatefulWidget {
  const FlutterCraftIAScreen({super.key});

  @override
  State<FlutterCraftIAScreen> createState() => _FlutterCraftIAScreenState();
}

class _FlutterCraftIAScreenState extends State<FlutterCraftIAScreen> {
  // ⚠️ CONFIGURATION DE L'URL BACKEND RUST :
  // Remplacez cette URL par celle de votre serveur de production Render ou de votre Codespace.
  // Ne mettez pas de "/" à la fin de l'adresse.
  static const String backendUrl = "https://aegis-flux-backend.onrender.com";
  _AppMode _mode = _AppMode.genui;

  final TextEditingController _instructionsController = TextEditingController(
    text: "Crée un écran de connexion moderne avec validation d'email, mot de passe masquable et un bouton bleu dégradé.",
  );

  String _generatedCode = '';
  bool _isLoading = false;
  int _userCredits = 10;
  bool statut_premium = false;
  final TextEditingController _activationCodeController = TextEditingController();

  // ───────── AEGIS-FLUX scanner ─────────
  final TextEditingController _scanCodeController = TextEditingController();
  final TextEditingController _scanFilenameController = TextEditingController(text: 'snippet.dart');
  bool _isScanning = false;
  String _scanResult = '';
  List<Map<String, dynamic>> _scanVulnerabilities = [];
  // ─────────────────────────────────────

  final List<String> _quickSuggestions = [
    "Écran de connexion moderne",
    "Bouton animé avec gradient",
    "Carte de produit e-commerce",
    "Architecture BLoC 8.x",
    "Riverpod 2.x Notifier",
    "Client API Dio avec JWT",
  ];

  @override
  void dispose() {
    _instructionsController.dispose();
    _activationCodeController.dispose();
    _scanCodeController.dispose();
    _scanFilenameController.dispose();
    super.dispose();
  }

  // LIAISON RÉELLE ET CORRIGÉE AVEC LE SERVEUR RUST
  void _onGeneratePressed() async {
    final query = _instructionsController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _generatedCode = "";
    });

    try {
      final cleanUrl = backendUrl.endsWith('/')
          ? backendUrl.substring(0, backendUrl.length - 1)
          : backendUrl;

      final response = await http.post(
        Uri.parse("$cleanUrl/v1/fluttercraft/generate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": query, "mode": "scaffold"}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedCode = data['code_dart'];
          if (!statut_premium && _userCredits > 0) _userCredits--;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code Flutter généré avec succès !'),
            backgroundColor: Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _generatedCode = "// Erreur retournée par le serveur Rust (Code HTTP: ${response.statusCode})\n// Vérifiez les logs de votre backend.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generatedCode = "// Impossible de joindre votre serveur distant Rust.\n// Erreur réseau : $e\n\n// ACTIONS REQUISES :\n// 1. Assurez-vous que l'URL 'backendUrl' déclarée en haut de votre main.dart est correcte.\n// 2. Vérifiez que votre serveur de production est bien actif.";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ───────── AEGIS-FLUX : Scanner de sécurité ─────────
  void _onScanPressed() async {
    final code = _scanCodeController.text.trim();
    if (code.isEmpty || _isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResult = '';
      _scanVulnerabilities = [];
    });

    try {
      final cleanUrl = backendUrl.endsWith('/')
          ? backendUrl.substring(0, backendUrl.length - 1)
          : backendUrl;

      final response = await http.post(
        Uri.parse('$cleanUrl/v1/aegis/scan-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code_dart': code,
          'filename': _scanFilenameController.text.trim().isEmpty
              ? 'snippet.dart'
              : _scanFilenameController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _scanResult = (data['report_markdown'] as String?) ?? '';
          final list = data['vulnerabilities'] as List<dynamic>? ?? [];
          _scanVulnerabilities = list.cast<Map<String, dynamic>>();
          if (!statut_premium && _userCredits > 0) _userCredits--;
        });
      } else {
        setState(() {
          _scanResult = '// Erreur HTTP ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanResult = '// Erreur réseau : $e\n// Vérifiez que le backend est actif.';
      });
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }
  // ─────────────────────────────────────────────────────

  void _copyToClipboard() {
    if (_generatedCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code Dart copié dans le presse-papiers !'),
        backgroundColor: Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMetaMaskDonationDialog() {
    const String cryptoAddress = "0x5a09e3CF9A22b5c4E6688B939D6B157fA7E50F79";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6851B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Color(0xFFF6851B), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Soutenir un projet solidaire',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge Statut actuel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statut_premium
                            ? const Color(0xFF15803D).withOpacity(0.2)
                            : const Color(0xFF0284C7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: statut_premium ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statut_premium ? "STATUT : PREMIUM ILLIMITÉ À VIE 👑" : "VOS CRÉDITS DISPONIBLES :",
                            style: TextStyle(
                              color: statut_premium ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (!statut_premium)
                            Text(
                              "$_userCredits crédits",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Explication de l'équivalence des privilèges
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Les deux modes de soutien débloquent exactement les mêmes privilèges d'accès complet, de crédits et de fonctionnalités pour l'application.",
                              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 1. 💳 OPTION STANDARD : GITHUB SPONSORS / CARTE BANCAIRE
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.credit_card_rounded, color: Color(0xFF38BDF8), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "1. 💳 Option Standard : GitHub Sponsors / CB",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Paiement sécurisé par Carte Bancaire via GitHub Sponsors. Génère automatiquement une facture déductible avec TVA pour les entreprises et les professionnels.",
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              const sponsorUrl = "https://github.com/sponsors";
                              Clipboard.setData(const ClipboardData(text: sponsorUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Lien GitHub Sponsors copié ! (Facturation pro disponible)"),
                                  backgroundColor: Color(0xFF0284C7),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text(
                              "Soutenir via GitHub Sponsors (CB / Facture)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. 🦊 OPTION WEB3 : METAMASK (CRYPTO)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF6851B).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.currency_bitcoin_rounded, color: Color(0xFFF6851B), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "2. 🦊 Option Web3 : MetaMask (Crypto)",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Transfert crypto direct sans intermédiaire. Réseaux recommandés : Polygon (MATIC) et BNB Chain (BEP-20).",
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: SelectableText(
                                    cryptoAddress,
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 18),
                                  tooltip: "Copier l'adresse",
                                  onPressed: () {
                                    Clipboard.setData(const ClipboardData(text: cryptoAddress));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Adresse Polygon/BNB copiée dans le presse-papiers !"),
                                        backgroundColor: Color(0xFF15803D),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: cryptoAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Adresse MetaMask copiée (Polygon / BNB Chain) !"),
                                  backgroundColor: Color(0xFF15803D),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFF6851B)),
                            label: const Text(
                              "Copier l'adresse (Polygon / BNB)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFF6851B)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF6851B)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF1E293B), thickness: 1),
                    const SizedBox(height: 12),

                    // 1. SECTION ALTERNATIVE (Ni Stripe ni Crypto)
                    Row(
                      children: const [
                        Icon(Icons.share_rounded, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Option Alternative : Partager sur les réseaux (Gratuit)",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Partagez l'outil sur LinkedIn ou Twitter pour recevoir immédiatement +5 crédits de génération.",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _userCredits += 5;
                        });
                        setDialogState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Partage validé ! +5 crédits ajoutés (Total: $_userCredits crédits)",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF15803D),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text(
                        "Partager sur LinkedIn / Twitter",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF1E293B), thickness: 1),
                    const SizedBox(height: 12),

                    // 2. SECTION CODE D'ACTIVATION
                    Row(
                      children: const [
                        Icon(Icons.school_rounded, color: Color(0xFFFBBF24), size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Code d'activation (Étudiants/Contributeurs)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (statut_premium)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF22C55E)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Code STUDENT2026 activé. Accès illimité à vie débloqué !",
                                style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _activationCodeController,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                hintText: "Code d'activation (ex: STUDENT2026)",
                                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                filled: true,
                                fillColor: const Color(0xFF0A0F1D),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF334155)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF0284C7)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              final inputCode = _activationCodeController.text.trim();
                              if (inputCode.toUpperCase() == "STUDENT2026") {
                                setState(() {
                                  statut_premium = true;
                                });
                                setDialogState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Code STUDENT2026 validé ! Statut Premium et accès illimité à vie débloqués 🎉",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF15803D),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Code d'activation invalide. Essayez STUDENT2026."),
                                    backgroundColor: Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            child: const Text("Valider", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fermer', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: cryptoAddress));
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Adresse MetaMask copiée dans le presse-papiers !",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    "Copier l'adresse",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code_rounded, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'FlutterCraft IA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
              ),
              child: const Text(
                'STUDIO IA',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _showMetaMaskDonationDialog,
              icon: const Icon(Icons.favorite_rounded, color: Color(0xFFF6851B), size: 16),
              label: const Text(
                'Soutenir via MetaMask (5€)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6851B).withOpacity(0.18),
                foregroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(color: Color(0xFFF6851B), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _mode = _AppMode.genui),
                      icon: Icon(Icons.auto_awesome, size: 20,
                          color: _mode == _AppMode.genui ? Colors.white : const Color(0xFF94A3B8)),
                      label: Text(
                        'FLUTTERCRAFT',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8,
                          color: _mode == _AppMode.genui ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mode == _AppMode.genui ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                        elevation: _mode == _AppMode.genui ? 6 : 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                        ),
                        side: BorderSide(
                          color: _mode == _AppMode.genui ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _mode = _AppMode.aegis),
                      icon: Icon(Icons.security, size: 20,
                          color: _mode == _AppMode.aegis ? Colors.white : const Color(0xFF94A3B8)),
                      label: Text(
                        'AEGIS-FLUX',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8,
                          color: _mode == _AppMode.aegis ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mode == _AppMode.aegis ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        elevation: _mode == _AppMode.aegis ? 6 : 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                        ),
                        side: BorderSide(
                          color: _mode == _AppMode.aegis ? const Color(0xFFEF4444) : const Color(0xFF334155),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: (_userCredits <= 0 && !statut_premium) ? _buildLockedView() : LayoutBuilder(
        builder: (context, constraints) {
        if (_mode == _AppMode.aegis) {
          return _buildAegisSection();
        }
          final isWide = constraints.maxWidth >= 720;

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildInputSection(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildTerminalSection(),
                  ),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  SizedBox(height: 400, child: _buildInputSection()),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500,
                    child: _buildTerminalSection(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAegisSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 1, child: _buildAegisInputSection()),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildAegisResultSection()),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                SizedBox(height: 400, child: _buildAegisInputSection()),
                const SizedBox(height: 16),
                SizedBox(height: 500, child: _buildAegisResultSection()),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildAegisInputSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text(
                'AEGIS-FLUX — SCANNER',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'CODE DART À ANALYSER :',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _scanCodeController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontFamily: 'monospace', height: 1.4),
              decoration: InputDecoration(
                hintText: "Collez ici le code Dart à scanner...\n\nex: const apiKey = 'gsk_...';",
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'monospace'),
                filled: true,
                fillColor: const Color(0xFF0A0F1D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _scanFilenameController,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Nom du fichier',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              filled: true,
              fillColor: const Color(0xFF0A0F1D),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isScanning ? null : _onScanPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFDC2626).withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isScanning
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'ANALYSE EN COURS...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'SCANNER LES FAILLES',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAegisResultSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'RAPPORT DE SÉCURITÉ',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (_scanVulnerabilities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_scanVulnerabilities.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isScanning
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2.5),
                        SizedBox(height: 18),
                        Text(
                          '[ANALYSE DE SÉCURITÉ EN COURS]',
                          style: TextStyle(color: Color(0xFFEF4444), fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '> Groq analyse le code selon OWASP Mobile...\n> Détection des failles en temps réel...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : _scanResult.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 48, color: const Color(0xFFEF4444).withOpacity(0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'SCANNER EN LIGNE',
                              style: TextStyle(color: Color(0xFFEF4444), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Collez du code Dart à gauche\net cliquez sur "SCANNER LES FAILLES".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 11.5),
                            ),
                          ],
                        ),
                      )
                    : _scanVulnerabilities.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'AUCUNE FAILLE DÉTECTÉE',
                                  style: TextStyle(color: Color(0xFF22C55E), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Le code semble sécurisé selon OWASP Mobile Top 10.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 11.5),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _scanVulnerabilities.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _buildVulnerabilityCard(_scanVulnerabilities[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildVulnerabilityCard(Map<String, dynamic> v) {
    final severity = (v['severity'] as String?) ?? 'INFO';
    final title = (v['title'] as String?) ?? 'Sans titre';
    final description = (v['description'] as String?) ?? '';
    final fix = (v['fix'] as String?) ?? '';
    final cwe = v['cwe'] as String?;
    final line = v['line'];

    Color sevColor;
    switch (severity.toUpperCase()) {
      case 'HIGH':
        sevColor = const Color(0xFFDC2626);
        break;
      case 'MEDIUM':
        sevColor = const Color(0xFFF59E0B);
        break;
      case 'LOW':
        sevColor = const Color(0xFF3B82F6);
        break;
      default:
        sevColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sevColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (cwe != null) ...[
                const SizedBox(width: 8),
                Text(
                  cwe,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
              if (line != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Ligne $line',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
          ),
          if (fix.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build_circle, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fix,
                      style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 80, color: Color(0xFFDC2626)),
            const SizedBox(height: 20),
            const Text(
              'QUOTA ATTEINT',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vous avez utilisé vos 5 crédits gratuits.\nDébloquez un accès illimité à vie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse('https://github.com/sponsors/ferhatBOUCHENNA');
                await launchUrl(url);
              },
              icon: const Icon(Icons.favorite),
              label: const Text('DÉBLOQUER VIA GITHUB SPONSORS (5€)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6851B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            const Text('OU CODE ÉTUDIANT :', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _activationCodeController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'STUDENT2026',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                if (_activationCodeController.text.trim().toUpperCase() == 'STUDENT2026') {
                  setState(() => statut_premium = true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code invalide'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Valider le code', style: TextStyle(color: Color(0xFF38BDF8))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 22),
              SizedBox(width: 8),
              Text(
                'SECTION DE SAISIE',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'INSTRUCTIONS POUR LE CODE FLUTTER :',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _instructionsController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              decoration: InputDecoration(
                hintText: "Ex: Crée un écran de connexion avec validation d'email, mot de passe masquable, bouton bleu...",
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0A0F1D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickSuggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF334155), width: 0.8),
                    onPressed: () => _instructionsController.text = s,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isLoading ? null : _onGeneratePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF0284C7).withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'COMMUNICATION SERVEUR EN COURS...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'GÉNÉRER LE CODE FLUTTER',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalSection() {
    const neonGreen = Color(0xFF00FF66);
    const pureBlack = Color(0xFF000000);

    return Container(
      decoration: BoxDecoration(
        color: pureBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLoading ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0F1D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    const Icon(Icons.terminal_rounded, color: neonGreen, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'fluttercraft_output.dart',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_generatedCode.isNotEmpty && !_isLoading)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: neonGreen, size: 18),
                    tooltip: 'Copier le code',
                    onPressed: _copyToClipboard,
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              color: neonGreen,
              backgroundColor: Color(0xFF0F172A),
              minHeight: 2,
            ),
          Expanded(
            child: Container(
              color: pureBlack,
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: neonGreen, strokeWidth: 2.5),
                          const SizedBox(height: 18),
                          Text(
                            '[REQUÊTE CLOUD TRANSMISE]',
                            style: TextStyle(color: neonGreen, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '> Le serveur Rust interroge Groq LPU...\n> Génération de code en temps réel...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF15803D), fontFamily: 'monospace', fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : _generatedCode.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.terminal_rounded, size: 48, color: neonGreen.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              const Text(
                                'TERMINAL EN LIGNE • CONFIGURÉ',
                                style: TextStyle(color: neonGreen, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Écrivez vos instructions à gauche et cliquez sur\n\"GÉNÉRER LE CODE FLUTTER\".\nLe code renvoyé par Groq s'affichera ici.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 11.5),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              _generatedCode,
                              style: const TextStyle(
                                color: neonGreen,
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0F1D),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _generatedCode.isNotEmpty
                      ? '${_generatedCode.split('\n').length} lignes • Connecté API'
                      : 'Prêt pour production',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'),
                ),
                TextButton.icon(
                  onPressed: _generatedCode.isNotEmpty && !_isLoading ? _copyToClipboard : null,
                  icon: const Icon(Icons.copy, size: 14, color: neonGreen),
                  label: const Text(
                    'COPIER LE CODE',
                    style: TextStyle(color: neonGreen, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
