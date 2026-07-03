import 'package:flutter/material.dart';

/// Primary brand color used throughout the app.
const Color kPrimaryBlue = Color(0xFF3B82F6);

/// Builds a standard [InputDecoration] with rounded borders and the app's
/// primary focus color. Use this for all text form fields to keep styling
/// consistent and avoid repeating the same decoration boilerplate.
InputDecoration buildAppInputDecoration({
  required String labelText,
  required IconData prefixIcon,
  Widget? suffixIcon,
  String? hintText,
  String? helperText,
  int? helperMaxLines,
  TextInputType? keyboardType,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: Icon(prefixIcon),
    suffixIcon: suffixIcon,
    helperText: helperText,
    helperMaxLines: helperMaxLines,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
    ),
  );
}

/// A reusable elevated button that shows a [CircularProgressIndicator] while
/// [isLoading] is true. Keeps styling consistent across all submit buttons.
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Creates a [PageRouteBuilder] with a horizontal slide transition.
/// Used for all page navigations that should slide in from the right.
Route<T> buildSlidePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
