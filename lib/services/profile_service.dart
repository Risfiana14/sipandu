import 'package:sipandu/models/user_profile.dart';

// Singleton service to maintain user profile data across the app
class UserService {
  // Singleton instance
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal();
  
  // User profile data
  UserProfile? _userProfile;
  
  // Getter for user profile
  UserProfile? get userProfile => _userProfile;
  
  // Set initial profile data
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
  }
  
  // Update profile data
  void updateUserProfile(UserProfile updatedProfile) {
    _userProfile = updatedProfile;
    
    // Here you would typically also save to backend/database
    // For example: apiService.updateProfile(updatedProfile);
  }
  
  // Check if profile is loaded
  bool get isProfileLoaded => _userProfile != null;
}