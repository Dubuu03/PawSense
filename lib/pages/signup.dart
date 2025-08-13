import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(40, 10, 40, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/img/image1.png',
                  height: 60,
                ),
                const SizedBox(height: 4),
                const Text(
                  'PawSense.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )),
                const SizedBox(height: 12),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  keyboardType: TextInputType.emailAddress,
                )),
                const SizedBox(height: 12),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Contact number',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  keyboardType: TextInputType.phone,
                )),
                const SizedBox(height: 12),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )),
                const SizedBox(height: 12),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  readOnly: true,
                )),
                const SizedBox(height: 12),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(Icons.visibility_outlined, color: Colors.grey, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  obscureText: true,
                )),
                const SizedBox(height: 12),

                _fieldContainer(const TextField(
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(Icons.visibility_outlined, color: Colors.grey, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  obscureText: true,
                )),
                const SizedBox(height: 12),

                // Checkbox for Terms and Conditions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: false,
                        onChanged: (val) {},
                        activeColor: const Color(0xFF2F4157),
                      ),
                    ),
                    const Text(
                      'I agree to the Terms and Conditions',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: Container(
                    decoration: _buttonShadow(),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        backgroundColor: const Color(0xFF2F4157),
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Sign In Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signin');
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2F4157),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 0, top: 0),
              child: Image.asset(
                'assets/img/image 9.png',
                height: 175,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _fieldContainer(Widget child) {
    return Container(
      height: 45,
      decoration: _boxDecoration(),
      child: child,
    );
  }

  static BoxDecoration _boxDecoration() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      borderRadius: BorderRadius.circular(15),
    );
  }

  static BoxDecoration _buttonShadow() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
      borderRadius: BorderRadius.circular(15),
    );
  }
}
