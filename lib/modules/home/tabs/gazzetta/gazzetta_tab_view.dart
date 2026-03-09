import 'package:flutter/material.dart';
import 'package:stopandgo/modules/gazzetta/gazzetta_view.dart';

class GazzettaTabView extends StatelessWidget {
  const GazzettaTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const GazzettaView(embedded: true);
  }
}
