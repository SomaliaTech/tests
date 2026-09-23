import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';

// ============================================================
// LANGUAGE / TRANSLATIONS
// ============================================================
enum AppLanguage { english, somali }

class _T {
  final AppLanguage lang;
  const _T(this.lang);

  String _v(String en, String so) => lang == AppLanguage.english ? en : so;

  // Header
  String get headerTitle => _v('Affiliate Program', 'Barnaamijka Xiriirka');
  String get headerSubtitle =>
      _v('Join the elite creators', 'Ku biir hal-abuurayaasha');

  // Hero
  String get exclusiveProgram => _v('EXCLUSIVE PROGRAM', 'BARNAAMIJ GAAR AH');
  String get heroTitle => _v(
    'Earn money\nby sharing\nwhat you love',
    'Lacag ku kasbo\nmarkaad la\nwadaagto waxaad jeceshahay',
  );
  String get heroSubtitle => _v(
    'Join 200+ creators earning commissions on every sale through their unique codes.',
    'Ku biir 200+ hal-abuure oo lacag ka helaya iib kasta oo ka dhaca koodhkooda gaarka ah.',
  );
  String get reviewedIn24h =>
      _v('Reviewed within 24 hours', 'Dib u eegis 24 saac gudahood');
  String get notifyApproved => _v(
    "We'll notify you once approved",
    'Waan kuu soo sheegi doonaa markii la ansixiyo',
  );

  // Stats
  String get creators => _v('Creators', 'Hal-abuurayaal');
  String get perSale => _v('Per Sale', 'Iib kasta');
  String get review => _v('Review', 'Dib u eegis');

  // How it works
  String get howItWorks => _v('How it works', 'Sida ay u shaqeyso');
  String get step1Title => _v('Submit Application', 'Gudbi Codsi');
  String get step1Desc => _v(
    'Fill out the form below with your details',
    'Buuxi foomka hoose faahfaahintaada',
  );
  String get step2Title => _v('Get Approved', 'Hel Ansixinta');
  String get step2Desc => _v(
    'Our team reviews within 24 hours',
    'Kooxdayadu waxay dib u eegtaa 24 saac gudahood',
  );
  String get step3Title => _v('Receive Your Code', 'Hel Koodhkaaga');
  String get step3Desc => _v(
    'Get a unique promo code to share',
    'Hel koodh gaar ah oo aad la wadaagto',
  );
  String get step4Title => _v('Earn Commission', 'Kasbo Komishan');
  String get step4Desc => _v(
    'Get paid for every order using your code',
    'Lacag ka hel amar kasta oo koodhkaaga isticmaala',
  );

  // Benefits
  String get whatYouGet => _v('What you get', 'Waxa aad helayso');
  String get benefit1 =>
      _v('5% commission on every sale', '5% komishan iib kasta');
  String get benefit2 =>
      _v('Your unique promo code', 'Koodhkaaga promoshinka gaarka ah');
  String get benefit3 => _v(
    'Real-time earnings dashboard',
    'Shaashadda faa\'iidada waqtiga-dhabta ah',
  );
  String get benefit4 =>
      _v('Monthly payouts to your account', 'Bixinta bishii account-kaaga');
  String get benefit5 =>
      _v('Dedicated affiliate support', 'Taageero xiriir gaar ah');

  // Form
  String get yourApplication => _v('Your Application', 'Codsiyadaada');
  String get formSubtitle => _v(
    "Fill out your details — we'll review and get back to you.",
    'Buuxi faahfaahintaada — waan dib u eegi doonaa oo waan kula soo xiriiri doonaa.',
  );
  String get businessName =>
      _v('Business / Brand Name', 'Magaca Ganacsiga / Summada');
  String get businessHint => _v('e.g., Style Boutique', 'tus. Style Boutique');
  String get businessRequired =>
      _v('Please enter your business name', 'Fadlan geli magaca ganacsigaaga');
  String get businessMinLength => _v(
    'At least 2 characters required',
    'Ugu yaraan 2 xaraf ayaa loo baahan yahay',
  );
  String get phoneNumber => _v('Phone Number', 'Lambarka Taleefanka');
  String get socialLinks =>
      _v('Social Media Links', 'Xiriirka Baraha Bulshada');
  String get socialHint =>
      _v('Instagram, TikTok, YouTube...', 'Instagram, TikTok, YouTube...');
  String get audienceSize => _v('Audience Size', 'Baaxadda Dhagaystayaasha');
  String get audienceHint => _v('e.g., 50k followers', 'tus. 50k raacayaal');
  String get aboutYourself =>
      _v('Tell us about yourself', 'Nala soo wadaag naftaada');
  String get aboutHint =>
      _v('What content do you create?', 'Waxa aad abuurto waa maxay?');
  String get required => _v('REQUIRED', 'WAJIB');
  String get termsPrefix => _v('I agree to the ', 'Waxaan ogolaanayaa ');
  String get termsLink =>
      _v('Affiliate Program Terms', 'Shuruudaha Barnaamijka Xiriirka');
  String get termsSuffix => _v(
    ' and understand that no promo code will be created until approved.',
    ' oo waxaan fahmayaa in aan koodh promo la abuuri doonin ilaa la ansixiyo.',
  );
  String get submitApplication => _v('Submit Application', 'Gudbi Codsi');
  String get maybeLater => _v('Maybe later', 'Waqti kale');
  String get agreeError => _v(
    'Please agree to the terms to continue',
    'Fadlan ogolaansho shuruudaha si aad u sii gudubto',
  );

  // Status screens
  String get pendingTitle => _v('Under Review', 'Dib u eegis');
  String get pendingHeadline =>
      _v('Application Under Review', 'Codsiyadaada Waa La Eegayaa');
  String get pendingMessage => _v(
    "Your affiliate application is being reviewed by our team. We'll notify you within 24 hours.",
    'Codsigaaga xiriirka waxaa dib u eegaya kooxdayada. Waxaan kuu soo sheegi doonaa 24 saac gudahood.',
  );
  String get pendingStatus => _v('STATUS: PENDING', 'XAALADDA: SUGITAAN');

  String get approvedHeadline =>
      _v('You\'re an Affiliate!', 'Waxaad Tahay Xiriir!');
  String get approvedMessage => _v(
    'You already have an active affiliate account. Head to your dashboard to track your earnings.',
    'Waxaad horey u lahayd akoon xiriir oo firfircoon. Tag dashboard-kaaga si aad u la socoto faa\'iidadaada.',
  );

  String get rejectedHeadline =>
      _v('Application Not Approved', 'Codsiyadaada Lama Ansixin');
  String get rejectedMessage => _v(
    'Your previous application was not approved. You can submit a new one below.',
    'Codsigaagii hore lama ansixin. Waxaad gudbin kartaa mid cusub hoos.',
  );

  String get backToHome => _v('Back to Home', 'Ku noqo Guriga');
  String get goToDashboard => _v('Go to Dashboard', 'Tag Dashboard');
  String get tryAgain => _v('Try Again', 'Isku day mar kale');
}

// ============================================================
// SCREEN
// ============================================================
class AffiliateApplyScreen extends StatefulWidget {
  const AffiliateApplyScreen({super.key});

  @override
  State<AffiliateApplyScreen> createState() => _AffiliateApplyScreenState();
}

class _AffiliateApplyScreenState extends State<AffiliateApplyScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _socialLinksController = TextEditingController();
  final _audienceController = TextEditingController();
  bool _isApplying = false;
  bool _agreedToTerms = false;
  AppLanguage _lang = AppLanguage.english;
  _T get t => _T(_lang);

  late final AnimationController _orbController;
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<double> _heroFade;
  late final Animation<double> _statsFade;
  late final Animation<double> _stepsFade;
  late final Animation<double> _benefitsFade;
  late final Animation<double> _formFade;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _headerFade = _makeInterval(0.0, 0.4);
    _heroFade = _makeInterval(0.15, 0.6);
    _statsFade = _makeInterval(0.3, 0.7);
    _stepsFade = _makeInterval(0.45, 0.85);
    _benefitsFade = _makeInterval(0.6, 0.95);
    _formFade = _makeInterval(0.7, 1.0);

    _entranceController.forward();

    // ✅ Fetch the affiliate status on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AffiliateUserBloc>().add(
        const FetchMyAffiliateProfileEvent(),
      );
    });
  }

  Animation<double> _makeInterval(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _socialLinksController.dispose();
    _audienceController.dispose();
    _orbController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _lang = _lang == AppLanguage.english
          ? AppLanguage.somali
          : AppLanguage.english;
    });
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ToastHelper.showError(context, t.agreeError);
      return;
    }

    setState(() => _isApplying = true);
    context.read<AffiliateUserBloc>().add(
      ApplyAffiliateEvent(
        businessName: _businessNameController.text.trim(),
        description: _buildApplicationDescription(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      ),
    );
  }

  String? _buildApplicationDescription() {
    final parts = <String>[];
    if (_descriptionController.text.trim().isNotEmpty) {
      parts.add(_descriptionController.text.trim());
    }
    if (_audienceController.text.trim().isNotEmpty) {
      parts.add('Audience: ${_audienceController.text.trim()}');
    }
    if (_socialLinksController.text.trim().isNotEmpty) {
      parts.add('Social: ${_socialLinksController.text.trim()}');
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AffiliateUserBloc, AffiliateUserState>(
      listenWhen: (previous, current) =>
          current is AffiliateUserOperationSuccess ||
          current is AffiliateUserError,
      listener: (context, state) {
        if (state is AffiliateUserOperationSuccess) {
          if (!mounted) return;
          setState(() => _isApplying = false);
          ToastHelper.showSuccess(context, state.message);
          Navigator.pop(context);
        } else if (state is AffiliateUserError) {
          if (!mounted) return;
          setState(() => _isApplying = false);
          ToastHelper.showError(context, state.message);
        }
      },
      child: BlocBuilder<AffiliateUserBloc, AffiliateUserState>(
        buildWhen: (prev, curr) =>
            curr is MyAffiliateProfileLoaded ||
            curr is AffiliateUserLoading ||
            curr is AffiliateUserError,
        builder: (context, state) {
          // Show loading while we check the profile
          if (state is AffiliateUserLoading && _isApplying == false) {
            // Only show full-screen loader on first load
            final isFirstLoad = !_hasFetchedProfile;
            if (isFirstLoad) {
              return _buildStatusLoader();
            }
          }

          // ✅ Has a profile loaded
          if (state is MyAffiliateProfileLoaded) {
            _hasFetchedProfile = true;

            if (state.isPending) {
              return _buildStatusScreen(
                variant: _StatusVariant.pending,
                profile: state.profile,
              );
            }

            if (state.isApproved) {
              return _buildStatusScreen(
                variant: _StatusVariant.approved,
                profile: state.profile,
              );
            }

            // Rejected or None → show the apply form
            // (rejected shows a banner at the top)
            return _buildApplyFormBody(isRejected: state.isRejected);
          }

          // Fallback — show form
          return _buildApplyFormBody(isRejected: false);
        },
      ),
    );
  }

  bool _hasFetchedProfile = false;

  // ============================================================
  // STATUS LOADER
  // ============================================================
  Widget _buildStatusLoader() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _orbController),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFA855F7),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Checking your status…',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS SCREENS (Pending / Approved / Rejected)
  // ============================================================
  Widget _buildStatusScreen({
    required _StatusVariant variant,
    required Map<String, dynamic>? profile,
  }) {
    Color accent;
    IconData icon;
    String headline;
    String message;
    String? chipText;

    switch (variant) {
      case _StatusVariant.pending:
        accent = const Color(0xFFFBBF24);
        icon = Iconsax.clock;
        headline = t.pendingHeadline;
        message = t.pendingMessage;
        chipText = t.pendingStatus;
        break;
      case _StatusVariant.approved:
        accent = const Color(0xFF34D399);
        icon = Iconsax.crown;
        headline = t.approvedHeadline;
        message = t.approvedMessage;
        chipText = null;
        break;
      case _StatusVariant.rejected:
        accent = const Color(0xFFEF4444);
        icon = Iconsax.close_circle;
        headline = t.rejectedHeadline;
        message = t.rejectedMessage;
        chipText = null;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _orbController),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _glassIconButton(
                        icon: Iconsax.arrow_left_2,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFA78BFA),
                              Color(0xFFF472B6),
                              Color(0xFFFBBF24),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            t.headerTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.15),
                          accent.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.4),
                                blurRadius: 28,
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: accent, size: 44),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          headline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 14,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (chipText != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.info_circle,
                                  color: accent,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  chipText,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        variant == _StatusVariant.approved
                            ? t.goToDashboard
                            : t.backToHome,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPLY FORM BODY (default)
  // ============================================================
  Widget _buildApplyFormBody({required bool isRejected}) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _orbController),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      children: [
                        if (isRejected) ...[
                          _buildRejectedBanner(),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 8),
                        _fadeSlide(_heroFade, _buildHeroSection()),
                        const SizedBox(height: 20),
                        _fadeSlide(_statsFade, _buildStatsStrip()),
                        const SizedBox(height: 20),
                        _fadeSlide(_stepsFade, _buildHowItWorks()),
                        const SizedBox(height: 20),
                        _fadeSlide(_benefitsFade, _buildBenefitsCard()),
                        const SizedBox(height: 20),
                        _fadeSlide(_formFade, _buildApplicationForm()),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.warning_2,
              color: Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.rejectedMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fadeSlide(Animation<double> anim, Widget child) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - anim.value)),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER + LANGUAGE TOGGLE
  // ============================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _glassIconButton(
            icon: Iconsax.arrow_left_2,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedBuilder(
              animation: _headerFade,
              builder: (_, __) {
                return Opacity(
                  opacity: _headerFade.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFA78BFA),
                            Color(0xFFF472B6),
                            Color(0xFFFBBF24),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          t.headerTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.headerSubtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildLanguageToggle(),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE TOGGLE
  // ============================================================
  Widget _buildLanguageToggle() {
    final isEn = _lang == AppLanguage.english;
    return GestureDetector(
      onTap: _toggleLanguage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langChip(
              label: 'EN',
              active: isEn,
              gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
            ),
            _langChip(
              label: 'SO',
              active: !isEn,
              gradient: const [Color(0xFFEC4899), Color(0xFFF59E0B)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _langChip({
    required String label,
    required bool active,
    required List<Color> gradient,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: active ? LinearGradient(colors: gradient) : null,
        borderRadius: BorderRadius.circular(100),
        boxShadow: active
            ? [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO SECTION
  // ============================================================
  Widget _buildHeroSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7C3AED).withValues(alpha: 0.9),
                const Color(0xFFA855F7).withValues(alpha: 0.85),
                const Color(0xFFEC4899).withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(painter: _GridDotPainter()),
                ),
              ),
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExclusiveBadge(),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFFEF3C7)],
                    ).createShader(bounds),
                    child: Text(
                      t.heroTitle,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t.heroSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildInfoChip(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExclusiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFBBF24),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFBBF24),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t.exclusiveProgram,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Iconsax.crown, color: Color(0xFFFBBF24), size: 12),
        ],
      ),
    );
  }

  Widget _buildInfoChip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.clock, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.reviewedIn24h,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.notifyApproved,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS STRIP
  // ============================================================
  Widget _buildStatsStrip() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            '200+',
            t.creators,
            Iconsax.people,
            const Color(0xFFA78BFA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            '5%',
            t.perSale,
            Iconsax.percentage_circle,
            const Color(0xFFF472B6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            '24h',
            t.review,
            Iconsax.clock,
            const Color(0xFFFBBF24),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ).createShader(bounds),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HOW IT WORKS
  // ============================================================
  Widget _buildHowItWorks() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Iconsax.route_square,
            title: t.howItWorks,
            color: const Color(0xFFA78BFA),
          ),
          const SizedBox(height: 22),
          _stepItem(
            number: '01',
            title: t.step1Title,
            description: t.step1Desc,
            color: const Color(0xFFA78BFA),
            isLast: false,
          ),
          _stepItem(
            number: '02',
            title: t.step2Title,
            description: t.step2Desc,
            color: const Color(0xFFC084FC),
            isLast: false,
          ),
          _stepItem(
            number: '03',
            title: t.step3Title,
            description: t.step3Desc,
            color: const Color(0xFFF472B6),
            isLast: false,
          ),
          _stepItem(
            number: '04',
            title: t.step4Title,
            description: t.step4Desc,
            color: const Color(0xFF34D399),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required String number,
    required String title,
    required String description,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.5),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BENEFITS CARD
  // ============================================================
  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.15),
            const Color(0xFFFBBF24).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Iconsax.gift,
            title: t.whatYouGet,
            color: const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 18),
          _benefitRow(
            Iconsax.percentage_circle,
            t.benefit1,
            const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 12),
          _benefitRow(
            Iconsax.discount_shape,
            t.benefit2,
            const Color(0xFFF472B6),
          ),
          const SizedBox(height: 12),
          _benefitRow(Iconsax.chart_2, t.benefit3, const Color(0xFFA78BFA)),
          const SizedBox(height: 12),
          _benefitRow(
            Iconsax.wallet_money,
            t.benefit4,
            const Color(0xFF34D399),
          ),
          const SizedBox(height: 12),
          _benefitRow(Iconsax.support, t.benefit5, const Color(0xFF60A5FA)),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Icon(
          Iconsax.tick_circle,
          color: color.withValues(alpha: 0.6),
          size: 16,
        ),
      ],
    );
  }

  // ============================================================
  // APPLICATION FORM
  // ============================================================
  Widget _buildApplicationForm() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Iconsax.edit_2,
              title: t.yourApplication,
              color: const Color(0xFFA78BFA),
            ),
            const SizedBox(height: 6),
            Text(
              t.formSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            _buildInputField(
              controller: _businessNameController,
              label: t.businessName,
              icon: Iconsax.building,
              hint: t.businessHint,
              required: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return t.businessRequired;
                }
                if (value.trim().length < 2) {
                  return t.businessMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _phoneController,
              label: t.phoneNumber,
              icon: Iconsax.call,
              hint: '+252 XX XXX XXXX',
              keyboardType: TextInputType.phone,
              required: false,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _socialLinksController,
              label: t.socialLinks,
              icon: Iconsax.global,
              hint: t.socialHint,
              required: false,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _audienceController,
              label: t.audienceSize,
              icon: Iconsax.people,
              hint: t.audienceHint,
              required: false,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _descriptionController,
              label: t.aboutYourself,
              icon: Iconsax.document_text,
              hint: t.aboutHint,
              maxLines: 4,
              required: false,
            ),
            const SizedBox(height: 22),

            _buildTermsCheckbox(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isApplying ? null : () => Navigator.pop(context),
                child: Text(
                  t.maybeLater,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _agreedToTerms
              ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _agreedToTerms
                ? const Color(0xFFA78BFA).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                gradient: _agreedToTerms
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      )
                    : null,
                color: _agreedToTerms ? null : Colors.transparent,
                border: Border.all(
                  color: _agreedToTerms
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(7),
                boxShadow: _agreedToTerms
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: _agreedToTerms
                  ? const Icon(
                      Iconsax.tick_circle,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: t.termsPrefix,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: t.termsLink,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA78BFA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: t.termsSuffix,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isDisabled = _isApplying || !_agreedToTerms;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _apply,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFFA855F7),
                      Color(0xFFEC4899),
                    ],
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: -4,
                    ),
                  ],
          ),
          child: Center(
            child: _isApplying
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.send_2,
                        color: isDisabled
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t.submitApplication,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDisabled
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.2,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.required,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFFA78BFA),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: const Color(0xFFA78BFA), size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 50,
                minHeight: 50,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================
  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(22),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATUS VARIANTS
// ============================================================
enum _StatusVariant { pending, approved, rejected }

// ============================================================
// ANIMATED MESH BACKGROUND
// ============================================================
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final v = controller.value;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A0F), Color(0xFF14101F)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100 + (v * 60),
                right: -120 + (v * 40),
                child: _GlowOrb(
                  size: 400,
                  color: const Color(0xFF7C3AED),
                  opacity: 0.35,
                ),
              ),
              Positioned(
                top: 300 - (v * 50),
                left: -160 + (v * 30),
                child: _GlowOrb(
                  size: 380,
                  color: const Color(0xFFEC4899),
                  opacity: 0.28,
                ),
              ),
              Positioned(
                bottom: 100 + (v * 40),
                right: -100 - (v * 30),
                child: _GlowOrb(
                  size: 320,
                  color: const Color(0xFFF59E0B),
                  opacity: 0.2,
                ),
              ),
              Positioned(
                bottom: -120 + (v * 50),
                left: -100 + (v * 60),
                child: _GlowOrb(
                  size: 350,
                  color: const Color(0xFF3B82F6),
                  opacity: 0.18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DOT GRID PAINTER
// ============================================================
class _GridDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius = 1.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
