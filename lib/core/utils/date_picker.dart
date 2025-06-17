import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

class DatePicker {

   Future<DateTime?> selectDate(BuildContext context, {DateTime? initialDate}) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner une date',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );
  }

}
