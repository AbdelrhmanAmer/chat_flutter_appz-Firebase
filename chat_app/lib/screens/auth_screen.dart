import 'dart:developer';
import 'dart:io';

import 'package:chat_app/widgets/user_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loginMode = true;
  String _enteredEmail = '';
  String _enteredPassword = '';
  String _enteredUsername = '';
  File? _selectedImage;
  var _isUploading = false;
  void _summit()async
  {
    bool isValid = _formKey.currentState!.validate();
    if(!isValid || (!_loginMode && _selectedImage == null)){
      return ;
    }
    _formKey.currentState!.save();
    try
    {
      setState(() {
        _isUploading = true;
      });
      if (_loginMode)
      {
        final UserCredential userCredential = await _firebase
            .signInWithEmailAndPassword(
            email: _enteredEmail,
            password: _enteredPassword
        );
      }
      else
      {
        final UserCredential userCredential = await _firebase
            .createUserWithEmailAndPassword(
            email: _enteredEmail,
            password: _enteredPassword,
        );
        final Reference storageRef = FirebaseStorage.instance.ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final String imageUrl = await storageRef.getDownloadURL();
        log(imageUrl);

        final _firestore = FirebaseFirestore.instance
            .collection('users')
        .doc(userCredential.user!.uid)
        .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl

        });
      }
    }
    on FirebaseAuthException catch(e)
    {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? 'Authentication failed.')
      ),
      );
      setState(() {
        _isUploading = false;
      });
    }
    log(_enteredEmail);
    log(_enteredPassword);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.7),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: 200,
                child: Image.asset('assets/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if(!_loginMode)
                            UserImagePicker(onPickImage: (image)=> _selectedImage = image),
                          if(!_loginMode)
                            TextFormField(
                              decoration: const InputDecoration( labelText: "Username" ),
                              autocorrect: false,
                              onSaved: (value) =>  _enteredUsername = value!,
                              validator: (value){
                                if( value == null ||
                                    value.trim().length < 4)
                                {
                                  return 'Please enter at least 4 characters.';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 15,),
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: "Email Address"
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            onSaved: (value) =>  _enteredEmail = value!,
                            validator: (value){
                              if( value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@'))
                              {
                                return 'Please enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15,),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            onSaved: (value) =>  _enteredPassword = value! ,
                            validator: (value){
                              if( value == null ||
                                  value.trim().length<6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10,),
                          _isUploading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: _summit,
                            style: ElevatedButton.styleFrom( backgroundColor: Theme.of(context).colorScheme.primaryContainer ),
                            child: Text(_loginMode ? 'Login': 'Sign Up'),
                          ),
                          if(!_isUploading)
                            TextButton(
                              onPressed: (){
                                setState(() {
                                  _loginMode = !_loginMode;
                                });
                              },
                              child: Text(
                                _loginMode
                                    ? 'Create an account?'
                                    : 'I already have an account?',
                                style: const TextStyle(fontSize: 13),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
