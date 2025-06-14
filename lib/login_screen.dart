import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(title: Text("Login"),
            ),
            body: Center (
                child : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Username or Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                             obscureText: true,
                             decoration: InputDecoration(
                                labelText: 'Password',
                                 border: OutlineInputBorder(),
                                 ),
                            ),
                          SizedBox(height: 24),
                          ElevatedButton(
                          onPressed:() async {
                            try {
                                String email = 'test@example.com';
                                String password = '123456';

                                UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                                    email : email,
                                    password : password,
                                );
                                print('Logged in: ${userCredential.user?.email}');

                            }
                            catch (e){
                                print('Failed to login : $e');
                            }
                          },

                          child : Text('Login'),
                          ),
                        ],
                     ),
                )
            ),
        );
    }
}
