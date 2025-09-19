/// 密码相关常量
class PasswordConstants {
  /// 密码长度（固定长度）
  static const int passwordLength = 8;

  /// 登录PIN码长度（固定长度）
  static const int pinCodeLength = 8;

  /// 密码长度验证错误信息
  static const String passwordLengthError = '密码必须是8位';

  /// PIN码长度验证错误信息
  static const String pinCodeLengthError = '密码必须是8位';

  /// 密码为空错误信息
  static const String passwordEmptyError = '请输入密码';

  /// 密码不匹配错误信息
  static const String passwordMismatchError = '密码不匹配';

  /// 确认密码为空错误信息
  static const String confirmPasswordEmptyError = '请确认密码';
}
