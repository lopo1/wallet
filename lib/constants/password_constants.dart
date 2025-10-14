/// 密码相关常量
class PasswordConstants {
  /// 密码长度（固定长度）
  static const int passwordLength = 6;

  /// 登录PIN码长度（固定长度）
  static const int pinCodeLength = 6;

  /// 密码长度验证错误信息
  static const String passwordLengthError = '密码必须是6位';

  /// PIN码长度验证错误信息
  static const String pinCodeLengthError = '密码必须是6位';

  /// 密码为空错误信息
  static const String passwordEmptyError = '请输入密码';

  /// 密码不匹配错误信息
  static const String passwordMismatchError = '密码不匹配';

  /// 确认密码为空错误信息
  static const String confirmPasswordEmptyError = '请确认密码';

  // 统一的密码合法性校验：仅数字且固定长度
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length != passwordLength) return false;
    return RegExp(r'^\d+$').hasMatch(password);
  }

  // 统一的校验器：返回错误信息或 null
  static String? validatePassword(String password) {
    if (password.isEmpty) return passwordEmptyError;
    if (!isValidPassword(password)) return passwordLengthError;
    return null;
  }
}
