import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = "0";
  double? firstOperand;
  String? operator;
  bool shouldReset = false;

  final List<String> symbol = ["÷", "×", "-", "+"];
  final List<String> ctrlSymbol = ["AC", "+/-", "%"];

  void onButtonPressed(String label) {
    setState(() {
      if (label == "AC") {
        display = "0";
        firstOperand = null;
        operator = null;
        shouldReset = false;
      } else if (label == "+/-") {
        if (display != "0") {
          display = display.startsWith('-')
              ? display.substring(1)
              : '-$display';
        }
      } else if (label == "%") {
        double val = double.tryParse(display) ?? 0;
        display = (val / 100).toString();
      } else if (symbol.contains(label)) {
        firstOperand = double.tryParse(display);
        operator = label;
        shouldReset = true;
      } else if (label == "=") {
        if (firstOperand != null && operator != null) {
          double secondOperand = double.tryParse(display) ?? 0;
          switch (operator) {
            case "÷":
              display = (firstOperand! / secondOperand).toString();
              break;
            case "×":
              display = (firstOperand! * secondOperand).toString();
              break;
            case "-":
              display = (firstOperand! - secondOperand).toString();
              break;
            case "+":
              display = (firstOperand! + secondOperand).toString();
              break;
          }
          if (display.endsWith(".0"))
            display = display.substring(0, display.length - 2);
          firstOperand = null;
          operator = null;
          shouldReset = true;
        }
      } else {
        if (display == "0" || shouldReset) {
          display = (label == ".") ? "0." : label;
          shouldReset = false;
        } else {
          if (label == "." && display.contains(".")) return;
          display += label;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              alignment: Alignment.bottomRight,
              child: Text(
                display,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 60,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            for (int row = 0; row < 4; row++)
              Expanded(
                child: Row(
                  children: [
                    for (int col = 0; col < 4; col++)
                      Expanded(
                        child: _buildTile(
                          row: row,
                          col: col,
                          label: col == 3
                              ? symbol[row]
                              : row == 0
                              ? ctrlSymbol[col]
                              : '${[7, 8, 9, 4, 5, 6, 1, 2, 3][(row - 1) * 3 + col]}',
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTile(row: 4, col: 0, label: '0'),
                  ),
                  Expanded(child: _buildTile(row: 4, col: 2, label: '.')),
                  Expanded(child: _buildTile(row: 4, col: 3, label: '=')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required int row,
    required int col,
    required String label,
  }) {
    Color bgColor = const Color(0xFF333333);
    Color textColor = Colors.white;

    if (row == 0) {
      bgColor = Colors.white10;
      textColor = Colors.white;
    }
    if (col == 3) {
      bgColor = Colors.orangeAccent;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => onButtonPressed(label),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(1),
          border: row == 0 ? Border.all(color: Colors.white10) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
