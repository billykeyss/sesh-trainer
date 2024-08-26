import 'package:flutter/material.dart';

class GenderToggle extends StatefulWidget {
  final ValueChanged<String> onGenderChanged;
  final String initialGender;

  const GenderToggle({
    Key? key,
    required this.onGenderChanged,
    this.initialGender = 'Male',
  }) : super(key: key);

  @override
  _GenderToggleState createState() => _GenderToggleState();
}

class _GenderToggleState extends State<GenderToggle> {
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
  }

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Male'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Female'),
        ),
      ],
      isSelected: <bool>[
        _selectedGender == 'Male',
        _selectedGender == 'Female',
      ],
      onPressed: (index) {
        setState(() {
          _selectedGender = index == 0 ? 'Male' : 'Female';
          widget.onGenderChanged(_selectedGender);
        });
      },
      borderRadius: BorderRadius.circular(8.0),
      borderColor: Colors.blue,
      selectedBorderColor: Colors.blue,
      selectedColor: Colors.white,
      fillColor: Colors.blue,
    );
  }
}
