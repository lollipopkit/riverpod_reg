/// Annotation to mark a provider for registration in the generated providers class
class RegisterProvider {
  /// The type of provider to register
  final String? type;
  
  /// Optional custom name for the provider
  final String? name;
  
  /// Whether this provider should be included in read operations
  final bool includeRead;
  
  /// Whether this provider should be included in watch operations
  final bool includeWatch;
  
  /// Whether this provider should be included in notifier operations (for notifier providers)
  final bool includeNotifier;
  
  const RegisterProvider({
    this.type,
    this.name,
    this.includeRead = true,
    this.includeWatch = true,
    this.includeNotifier = true,
  });
}

/// Shorthand annotation for registering a provider
const registerProvider = RegisterProvider();