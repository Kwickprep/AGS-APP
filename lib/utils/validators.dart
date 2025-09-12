// lib/utils/validators.dart

class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Remove any whitespace
    value = value.trim();

    // More comprehensive email regex
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Check for common typos
    if (value.contains('..') || value.contains('@.') || value.contains('.@')) {
      return 'Please check your email format';
    }

    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    // Optional: Add more strict password requirements
    // if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
    //   return 'Password must contain uppercase, lowercase, and number';
    // }

    return null;
  }

  // Strong password validation (optional use)
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Phone number validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and parentheses for validation
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with + for international format
    if (cleanPhone.startsWith('+')) {
      // International format: +1234567890 (10-15 digits after +)
      if (!RegExp(r'^\+\d{10,15}$').hasMatch(cleanPhone)) {
        return 'Please enter a valid international phone number';
      }
    } else {
      // Local format: 10 digits
      if (!RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
        return 'Please enter a valid 10-digit phone number';
      }
    }

    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Generic required field validation
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Name validation (first name, last name)
  static String? name(String? value, [String fieldName = 'Name']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value
        .trim()
        .length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    // Only allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return '$fieldName can only contain letters';
    }

    return null;
  }

  // Username validation
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }

    // Only allow letters, numbers, underscores, and hyphens
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, _ and -';
    }

    return null;
  }

  // URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    final urlRegex = RegExp(
        r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$'
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Number validation
  static String? number(String? value, [String fieldName = 'Number']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Please enter a valid number';
    }

    return null;
  }

  // Decimal number validation
  static String? decimal(String? value, [String fieldName = 'Amount']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (!RegExp(r'^\d+\.?\d*$').hasMatch(value)) {
      return 'Please enter a valid amount';
    }

    return null;
  }

}