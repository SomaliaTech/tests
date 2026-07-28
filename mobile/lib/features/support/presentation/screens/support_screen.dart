// lib/features/support/presentation/screens/support_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/features/chat/presentation/widgets/admin_chat_bottom_sheet.dart';
import 'package:mobile/features/support/presentation/bloc/faq_bloc.dart';
import 'package:mobile/features/support/presentation/bloc/faq_event.dart';
import 'package:mobile/features/support/presentation/bloc/faq_state.dart';
import 'package:mobile/features/support/presentation/widgets/localization_helper.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  static Route route() =>
      MaterialPageRoute(builder: (_) => const SupportScreen());

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Load FAQs from backend
    context.read<FaqBloc>().add(const LoadActiveFaqsEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openInAppChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminChatBottomSheet(),
    );
  }

  Future<void> _makePhoneCall() async {
    final l10n = context.supportLocalization;
    final phoneUri = Uri(scheme: 'tel', path: l10n.phoneNumber);
    final smsUri = Uri(scheme: 'sms', path: l10n.phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        debugPrint('✅ Phone call initiated to: ${l10n.phoneNumber}');
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('✅ Opened SMS instead of call');
      } else {
        debugPrint('❌ Could not launch phone or SMS app');
      }
    } catch (e) {
      debugPrint('❌ Error launching phone call: $e');
    }
  }

  Future<void> _sendEmail() async {
    final l10n = context.supportLocalization;
    final emailUri = Uri(
      scheme: 'mailto',
      path: l10n.email,
      queryParameters: {'subject': 'Support Request - Faraxada'},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        debugPrint('✅ Email client opened for: ${l10n.email}');
      } else {
        debugPrint('❌ Could not launch email app');
      }
    } catch (e) {
      debugPrint('❌ Error launching email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.supportLocalization;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Green Gradient
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.arrow_left_2,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  l10n.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2ED573),
                      Color(0xFF1ABC9C),
                      Color(0xFF16A085),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Iconsax.headphone,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. IN-APP CHAT CARD
                    _buildInAppChatCard(l10n),

                    const SizedBox(height: 24),

                    // 2. OTHER CONTACT OPTIONS
                    Text(
                      l10n.otherWays,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactOptions(l10n),

                    const SizedBox(height: 32),

                    // 3. FAQ SECTION
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ED573).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.document_text,
                            color: Color(0xFF2ED573),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.faqTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dynamic FAQs from BLoC
                    BlocBuilder<FaqBloc, FaqState>(
                      builder: (context, state) {
                        if (state is FaqsLoading) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xFF2ED573),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.loadingFaqs,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is FaqsLoaded) {
                          if (state.faqs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Iconsax.document_text,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.noFaqs,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: state.faqs
                                .map(
                                  (faq) => FaqItem(
                                    question: faq.question,
                                    answer: faq.answer,
                                    isSomali: l10n.isSomali,
                                  ),
                                )
                                .toList(),
                          );
                        }

                        if (state is FaqError) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Iconsax.warning_2,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.errorLoadingFaqs,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.message,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<FaqBloc>().add(
                                        const LoadActiveFaqsEvent(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2ED573),
                                    ),
                                    child: Text(l10n.retry),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 40),

                    // 4. FOOTER
                    Center(
                      child: Column(
                        children: [
                          Text(
                            l10n.supportTeam,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.replyTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInAppChatCard(SupportLocalization l10n) {
    return GestureDetector(
      onTap: _openInAppChat,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ED573).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.messages_2,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chatWithAdmin,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.chatDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.arrow_right_2,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptions(SupportLocalization l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildContactButton(
            icon: Iconsax.call,
            title: l10n.callUs,
            subtitle: l10n.phoneNumber,
            color: const Color(0xFF3B82F6),
            onTap: _makePhoneCall,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildContactButton(
            icon: Iconsax.message,
            title: l10n.emailUs,
            subtitle: l10n.email,
            color: const Color(0xFFF59E0B),
            onTap: _sendEmail,
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// FAQ ACCORDION WIDGET with Localization
// ==========================================
class FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isSomali;

  const FaqItem({
    super.key,
    required this.question,
    required this.answer,
    this.isSomali = false,
  });

  @override
  State<FaqItem> createState() => FaqItemState();
}

class FaqItemState extends State<FaqItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? const Color(0xFF2ED573)
              : const Color(0xFFE5E7EB),
          width: _isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isExpanded
                            ? const Color(0xFF2ED573)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Iconsax.arrow_down_2,
                      color: _isExpanded
                          ? const Color(0xFF2ED573)
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textDirection: widget.isSomali
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            ),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
