import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';

class CreateHouseholdScreen extends StatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  State<CreateHouseholdScreen> createState() => _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends State<CreateHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final success = await context
        .read<HouseholdProvider>()
        .createHousehold(_nameController.text.trim());

    if (mounted) {
      if (success) {
        // Navigate to quick-setup for new household onboarding
        context.go('/quick-setup');
      } else {
        setState(() => _isCreating = false);
      }
    }
  }

  void _joinHousehold() {
    if (kDebugMode) {
      debugPrint('Join household tapped');
    }
    context.go('/join-household');
  }

  void _signOut() {
    if (kDebugMode) {
      debugPrint('Sign out tapped');
    }
    context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final householdProvider = context.watch<HouseholdProvider>();
    final displayName = authProvider.profile?.displayName ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.home_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, $displayName!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Let's set up your household",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Household Name',
                  hintText: 'e.g., The Smith House',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a household name';
                  }
                  return null;
                },
              ),
            ),
            if (householdProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  householdProvider.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createHousehold,
                icon: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Create Household'),
              ),
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _joinHousehold,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Join Existing Household'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
