import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const backendUrl = String.fromEnvironment('SUPABASE_URL');
const backendKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
SupabaseClient get backend => Supabase.instance.client;

Future<void> initializeBackend() async {
  final uri = Uri.tryParse(backendUrl);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      backendKey.isEmpty) {
    throw StateError(
      'Configure SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY for live mode.',
    );
  }
  await Supabase.initialize(
    url: backendUrl,
    publishableKey: backendKey,
    authOptions: const FlutterAuthClientOptions(persistSession: false),
  );
  // ponytail: sessions are memory-only; add native secure storage and a web
  // cookie backend when persistent sign-in becomes a launch requirement.
}

class BackendSignIn extends StatefulWidget {
  const BackendSignIn({super.key});
  @override
  State<BackendSignIn> createState() => _BackendSignInState();
}

class _BackendSignInState extends State<BackendSignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false, signup = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      setState(() => message = 'Enter a valid email address.');
      return;
    }
    if (!reset && password.text.length < 12) {
      setState(() => message = 'Use a password with at least 12 characters.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (reset) {
        await backend.auth.resetPasswordForEmail(email.text.trim());
        if (mounted) {
          setState(
            () => message =
                'If this account exists, a recovery email has been requested.',
          );
        }
      } else {
        final response = signup
            ? await backend.auth.signUp(
                email: email.text.trim(),
                password: password.text,
              )
            : await backend.auth.signInWithPassword(
                email: email.text.trim(),
                password: password.text,
              );
        if (!mounted) return;
        if (response.session != null) {
          Navigator.pop(context, true);
        } else {
          setState(
            () => message =
                'Check your email to confirm your account, then sign in.',
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Unable to reach sign-in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(signup ? 'Create your account' : 'Sign in to MobiMed'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sign in securely to manage your care and appointments.'),
          const SizedBox(height: 16),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Password',
              helperText: 'At least 12 characters',
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message!, semanticsLabel: message),
            ),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    signup = !signup;
                    message = null;
                  }),
            child: Text(
              signup ? 'Already have an account? Sign in' : 'Create an account',
            ),
          ),
          TextButton(
            onPressed: busy ? null : () => submit(reset: true),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy ? null : submit,
        child: Text(
          busy
              ? 'Please wait…'
              : signup
              ? 'Create account'
              : 'Sign in',
        ),
      ),
    ],
  );
}

class BackendPasswordUpdate extends StatefulWidget {
  const BackendPasswordUpdate({super.key});
  @override
  State<BackendPasswordUpdate> createState() => _BackendPasswordUpdateState();
}

class _BackendPasswordUpdateState extends State<BackendPasswordUpdate> {
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (password.text.length < 12) {
      setState(() => error = 'Use at least 12 characters.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await backend.auth.updateUser(UserAttributes(password: password.text));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Unable to update password. Request a fresh recovery link.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Set a new password'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: password,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        if (error != null) Text(error!),
      ],
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(busy ? 'Saving…' : 'Update password'),
      ),
    ],
  );
}
