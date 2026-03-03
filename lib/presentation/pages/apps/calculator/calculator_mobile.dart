import 'package:flutter/material.dart';

class CalculatorScreenMobile extends StatefulWidget {
  const CalculatorScreenMobile({super.key});

  @override
  State<CalculatorScreenMobile> createState() => _CalculatorScreenMobileState();
}

class _CalculatorScreenMobileState extends State<CalculatorScreenMobile> {
  // Calculator State Variables
  String _output = "0";
  String _currentNumber = "";
  double _num1 = 0;
  double _num2 = 0;
  String _operand = "";
  bool _shouldResetNumber = false;

  /// Handles all button press logic
  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _output = "0";
        _currentNumber = "";
        _num1 = 0;
        _num2 = 0;
        _operand = "";
        _shouldResetNumber = false;
      } else if (buttonText == "+" ||
          buttonText == "-" ||
          buttonText == "×" ||
          buttonText == "÷") {
        _num1 = double.tryParse(_output) ?? 0;
        _operand = buttonText;
        _shouldResetNumber = true;
      } else if (buttonText == ".") {
        if (_shouldResetNumber) {
          _output = "0.";
          _shouldResetNumber = false;
        } else if (!_output.contains(".")) {
          _output = _output + buttonText;
        }
      } else if (buttonText == "=") {
        _num2 = double.tryParse(_output) ?? 0;

        switch (_operand) {
          case "+":
            _output = (_num1 + _num2).toString();
            break;
          case "-":
            _output = (_num1 - _num2).toString();
            break;
          case "×":
            _output = (_num1 * _num2).toString();
            break;
          case "÷":
            _output = (_num1 / _num2).toString();
            break;
        }

        _operand = "";
        _shouldResetNumber = true;

        // Remove decimal if it's .0
        if (_output.endsWith(".0")) {
          _output = _output.substring(0, _output.length - 2);
        }
      } else if (buttonText == "+/-") {
        if (_output != "0") {
          if (_output.startsWith("-")) {
            _output = _output.substring(1);
          } else {
            _output = "-$_output";
          }
        }
      } else if (buttonText == "%") {
        double temp = double.tryParse(_output) ?? 0;
        _output = (temp / 100).toString();
      } else {
        // Handling Numbers
        if (_output == "0" || _shouldResetNumber) {
          _output = buttonText;
          _shouldResetNumber = false;
        } else {
          _output = _output + buttonText;
        }
      }
    });
  }

  /// Helper to create circular buttons
  Widget _buildButton(
    String text, {
    Color? color,
    Color? textColor,
    int flex = 1,
  }) {
    // Define standard colors if null
    final bgColor = color ?? const Color(0xFF333333); // Dark Grey
    final txtColor = textColor ?? Colors.white;

    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            shape: flex > 1 ? const StadiumBorder() : const CircleBorder(),
            padding: const EdgeInsets.all(24),
            elevation: 0,
          ),
          onPressed: () => _buttonPressed(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w100),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define Colors
    const Color orangeColor = Color(0xFFFF9F0A);
    const Color lightGreyColor = Color(0xFFA5A5A5);
    const Color darkGreyColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // --- Display Area ---
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _output,
                    style: const TextStyle(
                      fontSize: 90,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // --- Button Rows ---

            // Row 1
            Row(
              children: [
                _buildButton(
                  "AC",
                  color: lightGreyColor,
                  textColor: Colors.black,
                ),
                _buildButton(
                  "+/-",
                  color: lightGreyColor,
                  textColor: Colors.black,
                ),
                _buildButton(
                  "%",
                  color: lightGreyColor,
                  textColor: Colors.black,
                ),
                _buildButton("÷", color: orangeColor),
              ],
            ),

            // Row 2
            Row(
              children: [
                _buildButton("7", color: darkGreyColor),
                _buildButton("8", color: darkGreyColor),
                _buildButton("9", color: darkGreyColor),
                _buildButton("×", color: orangeColor),
              ],
            ),

            // Row 3
            Row(
              children: [
                _buildButton("4", color: darkGreyColor),
                _buildButton("5", color: darkGreyColor),
                _buildButton("6", color: darkGreyColor),
                _buildButton("-", color: orangeColor),
              ],
            ),

            // Row 4
            Row(
              children: [
                _buildButton("1", color: darkGreyColor),
                _buildButton("2", color: darkGreyColor),
                _buildButton("3", color: darkGreyColor),
                _buildButton("+", color: orangeColor),
              ],
            ),

            // Row 5 (0 spans 2 spaces)
            Row(
              children: [
                _buildButton("0", color: darkGreyColor, flex: 2),
                _buildButton(".", color: darkGreyColor),
                _buildButton("=", color: orangeColor),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
