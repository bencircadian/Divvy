import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/household_provider.dart';

class JoinHouseholdScreen extends StatefulWidget {
  final String? initialCode;

  const JoinHouseholdScreen({super.key, this.initialCode});

  @override
  State<JoinHouseholdScreen> createState() => _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends State<JoinHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinHousehold() async {
    if (!_formKey.currentState!.validate()) return;

    final householdProvider = context.read<HouseholdProvider>();
    final success = await householdProvider.joinHouseholdByCode(_codeController.text.trim());

    if (mounted && success) {
      // Go directly to home - joining existing household with tasks already set up
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/create-household'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.group_add_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join a Household',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the invite code shared with you',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _codeController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onFieldSubmitted: (_) => _joinHousehold(),
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      hintText: 'e.g., ABC123',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the invite code';
                      }
                      if (value.length != 6) {
                        return 'Invite code must be 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Consumer<HouseholdProvider>(
                    builder: (context, provider, _) {
                      if (provider.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<HouseholdProvider>(
                    builder: (context, provider, child) {
                      return FilledButton.icon(
                        onPressed: provider.isLoading ? null : _joinHousehold,
                        icon: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Join Household'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
