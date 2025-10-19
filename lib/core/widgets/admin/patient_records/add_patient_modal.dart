import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/validators.dart';

class AddPatientModal extends StatefulWidget {
  final void Function(Map<String, dynamic> patient)? onCreate;

  const AddPatientModal({super.key, this.onCreate});

  @override
  State<AddPatientModal> createState() => _AddPatientModalState();
}

class _AddPatientModalState extends State<AddPatientModal> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  // Pet Info
  final TextEditingController _petName = TextEditingController();
  String _petType = 'Dog';
  final TextEditingController _breed = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  String _gender = 'Male';
  final TextEditingController _color = TextEditingController();

  // Owner
  final TextEditingController _ownerName = TextEditingController();
  final TextEditingController _ownerPhone = TextEditingController();
  final TextEditingController _ownerEmail = TextEditingController();
  final TextEditingController _ownerAddress = TextEditingController();
  final TextEditingController _emergencyContact = TextEditingController();

  // Medical
  final TextEditingController _allergies = TextEditingController();
  final TextEditingController _conditions = TextEditingController();
  final TextEditingController _medications = TextEditingController();
  final TextEditingController _medicalNotes = TextEditingController();

  void _next() {
    if (_step == 0) {
      // validate pet info
      if ((_petName.text.isEmpty) || (_breed.text.isEmpty)) {
        // basic inline validation - rely on form validation in final submit
        setState(() {});
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    }
  }

  void _previous() {
    if (_step > 0) setState(() => _step--);
  }

  void _save() {
    // validate required owner & pet
    if (_formKey.currentState?.validate() ?? false) {
      final patient = {
        'petName': _petName.text,
        'petType': _petType,
        'breed': _breed.text,
        'age': _age.text,
        'weight': _weight.text,
        'gender': _gender,
        'color': _color.text,
        'ownerName': _ownerName.text,
        'ownerPhone': _ownerPhone.text,
        'ownerEmail': _ownerEmail.text,
        'ownerAddress': _ownerAddress.text,
        'emergencyContact': _emergencyContact.text,
        'allergies': _allergies.text,
        'conditions': _conditions.text,
        'medications': _medications.text,
        'medicalNotes': _medicalNotes.text,
      };

      widget.onCreate?.call(patient);
      Navigator.of(context).pop();
    } else {
      // If form invalid, move to first invalid step
      // simple heuristic: if owner fields invalid go to step 1
      setState(() {
        _step = 1;
      });
    }
  }

  Widget _buildStepIndicator(double width) {
    final labels = ['Pet Information', 'Owner Details', 'Medical History'];
    // Custom step indicator: 5-slot layout (circle, line, circle, line, circle)
    return Center(
      child: Container(
        width: width * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 72,
              child: Column(
                children: [
                  // Circles and lines in fixed slots so circles align with labels below
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(5, (slot) {
                        // even slots: circles (0,2,4) correspond to steps 0..2
                        if (slot % 2 == 0) {
                          final stepIndex = slot ~/ 2;
                          final completedOrActive = stepIndex <= _step;
                          final bgColor = completedOrActive ? AppColors.primary : Colors.grey.shade200;
                          final textColor = completedOrActive ? Colors.white : Colors.grey.shade700;
                          return Expanded(
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bgColor,
                                  border: completedOrActive ? null : Border.all(color: Colors.grey.shade300),
                                ),
                                child: Center(child: Text('${stepIndex + 1}', style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                              ),
                            ),
                          );
                        }

                        // odd slots: lines between circles
                        final leftStep = (slot - 1) ~/ 2; // index of left circle
                        final active = _step > leftStep;
                        return Expanded(
                          child: Center(
                            child: Container(
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: active ? AppColors.primary : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // labels under circles (3 labels aligned with 3 circle slots)
                  Row(
                    children: List.generate(3, (i) => Expanded(child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600])))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width * 0.5;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: mq.size.height * 0.9),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(Icons.pets, color: AppColors.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Patient',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Step ${_step + 1} of 3',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStepIndicator(width),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_step == 0) ...[
                            const SizedBox(height: 8),
                            const Text('Pet Information', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pet Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _petName,
                                        validator: (v) => requiredValidator(v, 'pet name'),
                                        maxLength: 20,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\-']")),
                                          LengthLimitingTextInputFormatter(20),
                                        ],
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(), 
                                          hintText: "Enter pet's name",
                                          counterText: "",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pet Type', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _petType,
                                        items: const [
                                          DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                                          DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                                        ],
                                        onChanged: (v) => setState(() => _petType = v ?? 'Dog'),
                                        decoration: const InputDecoration(border: OutlineInputBorder()),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Breed *', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _breed,
                                        validator: (v) => requiredValidator(v, 'breed'),
                                        maxLength: 50,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                                          LengthLimitingTextInputFormatter(50),
                                        ],
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(), 
                                          hintText: 'Enter breed',
                                          counterText: "",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Age *', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _age,
                                        maxLength: 3,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(), 
                                          hintText: 'e.g., 24',
                                          counterText: "",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Weight *', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _weight,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
                                        ],
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(), 
                                          hintText: 'e.g., 15.5',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _gender,
                                        items: const [
                                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                                        ],
                                        onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                                        decoration: const InputDecoration(border: OutlineInputBorder()),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      TextFormField(controller: _color, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Pet's color")),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            const Text('Pet Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text('Click to upload or drag and drop\nPNG, JPG up to 10MB', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600]))),
                            ),
                          ],
                          if (_step == 1) ...[
                            const SizedBox(height: 8),
                            const Text('Owner Details', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),

                            const Text('Owner Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _ownerName, 
                              validator: (v) => requiredValidator(v, 'owner name'), 
                              maxLength: 50,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                                LengthLimitingTextInputFormatter(50),
                              ],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: "Enter owner's full name",
                                counterText: "",
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600)), 
                                  const SizedBox(height: 8), 
                                  TextFormField(
                                    controller: _ownerPhone, 
                                    validator: phoneValidator, 
                                    maxLength: 11,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                    ],
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(), 
                                      hintText: '09123456789',
                                      counterText: "",
                                    ),
                                  ),
                                ])),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Email Address *', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), TextFormField(controller: _ownerEmail, validator: emailValidator, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'owner@email.com'))])),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _ownerAddress, 
                              maxLines: 3, 
                              maxLength: 200,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\-'.,#/]")),
                                LengthLimitingTextInputFormatter(200),
                              ],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: 'Home address',
                                counterText: "",
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emergencyContact, 
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: '09123456789',
                                counterText: "",
                              ),
                            ),
                          ],
                          if (_step == 2) ...[
                            const SizedBox(height: 8),
                            const Text('Medical History', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),

                            const Text('Known Allergies', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _allergies, 
                              maxLength: 300,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: 'List known allergies',
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Text('Existing Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _conditions, 
                              maxLength: 300,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: 'e.g., Diabetes',
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Text('Current Medications', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _medications, 
                              maxLength: 300,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: 'Medication names and dosages',
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _medicalNotes, 
                              maxLines: 4, 
                              maxLength: 300,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(), 
                                hintText: 'Any additional medical information',
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_step > 0)
                                TextButton(onPressed: _previous, child: const Text('Previous')),
                              const SizedBox(width: 12),
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _step == 2 ? _save : _next,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: Text(_step == 2 ? 'Create Patient' : 'Next Step'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
