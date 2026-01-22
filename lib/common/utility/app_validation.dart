
import 'package:iq_plus/common/utility/utility.dart';
import 'package:flutter/services.dart';

class AppValidation {
  static String? emptyPasswordValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your password.';
    } else {
      return null;
    }
  }

  static String? loginPasswordValidator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your password.';
    }  else {
      return null;
    }
  }
static String? phoneNumberValidator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your phone number.';
    }  else {
      return null;
    }
  }

static String? numberOfLocationValidator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your number of locations.';
    }  else {
      return null;
    }
  }

  static String? numberOfEmployeesValidator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your number of employees.';
    }  else {
      return null;
    }
  }

  static String? currentPasswordValidator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your password.';
    }
    else if (Utility.passwordValidationPattern(value: text.trim())) {
      return 'A minimum 8 characters password contains a combination of uppercase, lowercase, numerical letter and special character is required.';
    }
    else {
      return null;
    }
  }

  static String? confirmPasswordValidator(String? text, String passwordText) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your password.';
    } else if (Utility.passwordValidationPattern(value: text.trim())) {
      return 'A minimum 8 characters password contains a combination of uppercase, lowercase, numerical letter and special character is required.';
    } else if (text.trim() != passwordText.trim()) {
      return 'Password does not match.';
    } else {
      return null;
    }
  }

  static String? checkEmailValidation(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter your email.';
    } else if (Utility.emailValidationPattern(value: text)) {
      return 'Please enter valid email.';
    } else {
      return null;
    }
  }

  static String? nameValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your name.';
    }
    // else if(nameValidationPattern(text)){
    //   return 'space, number & special character are not allowed';
    // }
    else {
      return null;
    }
  }

  static String? deliveryAddressFieldsValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'You have not answered all required fields';
    }
    // else if(nameValidationPattern(text)){
    //   return 'space, number & special character are not allowed';
    // }
    else {
      return null;
    }
  }

  static String? subjectValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your subject.';
    } else {
      return null;
    }
  }

  static String? messageValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your message.';
    } else {
      return null;
    }
  }

  static String? streetNumberValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your name street number.';
    }
    // else if(nameValidationPattern(text)){
    //   return 'space, number & special character are not allowed';
    // }
    else {
      return null;
    }
  }

  static String? aptHouseNumberValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your apt / house number.';
    }
    // else if(nameValidationPattern(text)){
    //   return 'space, number & special character are not allowed';
    // }
    else {
      return null;
    }
  }
  static String? numberOfDineInGuestsValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter number of dine-in guests.';
    }
    // else if(nameValidationPattern(text)){
    //   return 'space, number & special character are not allowed';
    // }
    else {
      return null;
    }
  }

  static String? fNameValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your first name.';
    } else {
      return null;
    }
  }

  static String? lNameValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your last name.';
    } else {
      return null;
    }
  }

  static String? feedBackReviewValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter Order review.';
    } else {
      return null;
    }
  }

  static String? feedBackReviewValidator2(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter item review.';
    } else {
      return null;
    }
  }

  static String? resetCodeValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter your reset code.';
    }
    // else if(nameValidationPattern(text)){
    //   return 'space, number & special character are not allowed';
    // }
    else {
      return null;
    }
  }

  static String? tipValidator(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return 'Please enter tip.';
    } else {
      return null;
    }
  }

  static List<TextInputFormatter> nameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp("[a-zA-Z]"),
      ),
      LengthLimitingTextInputFormatter(20),
    ];
  }

  static List<TextInputFormatter> fullNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp("[a-z A-Z]"),
      ),
      LengthLimitingTextInputFormatter(30),
    ];
  }

  static bool nameValidationPattern(String text) {
    String pattern = r'^[0-9_\-=@,\.;]$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(text);
  }

  static List<TextInputFormatter> zipCodeFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp("[0-9]"),
      ),
      LengthLimitingTextInputFormatter(10),
    ];
  }

  static List<TextInputFormatter> phoneNumberFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp("[0-9]"),
      ),
      LengthLimitingTextInputFormatter(16),
    ];
  }

  static String? chefSubjectCheck(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return "Please enter subject";
    } else {
      return null;
    }
  }

  static String? chefMessageCheck(String? text) {
    if ((text ?? '').trim().isEmpty) {
      return "Please enter message";
    } else {
      return null;
    }
  }
}
