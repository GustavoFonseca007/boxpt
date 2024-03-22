import 'package:eco/login.dart';
import 'package:eco/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _showPassword = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset("images/logosemfundopreto.jpeg"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Rastreador de Treino',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                ),
                Text(
                  'Registar',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: Colors.black,
                    ),
                    hintText: 'E-Mail',
                  ),
                  validator: (email) {
                    if (email == null || email.isEmpty) {
                      return 'Digite o seu email!';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Colors.black,
                    ),
                    hintText: 'Nome de usuário',
                  ),
                  validator: (nome) {
                    if (nome == null || nome.isEmpty) {
                      return 'Digite o seu nome!';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _senhaController,
                  autofocus: false,
                  obscureText: _showPassword == false ? true : false,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Colors.black,
                    ),
                    hintText: 'Palavra-Passe',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                    suffixIcon: GestureDetector(
                      child: Icon(
                        _showPassword == false
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  validator: (senha) {
                    if (senha == null || senha.isEmpty) {
                      return 'Digite a sua senha!';
                    } else if (senha.length < 6) {
                      return 'Digite uma senha mais forte!';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 12,
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (_emailController.text.isEmpty ||
                          _senhaController.text.isEmpty ||
                          _nomeController.text.isEmpty) {
                        Fluttertoast.showToast(
                            msg: "Erro ao criar uma nova conta.");
                        return;
                      }

                      final emailExistente = await FirebaseAuth.instance
                          .fetchSignInMethodsForEmail(_emailController.text);
                      if (emailExistente.isNotEmpty) {
                        Fluttertoast.showToast(
                            msg: "Este email já está em uso.");
                        return;
                      }

                      final usuario = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: _emailController.text,
                        password: _senhaController.text,
                      );

                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(usuario.user!.uid)
                          .set({
                        'id': usuario.user!.uid,
                        'name': _nomeController.text,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Menu()),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        Fluttertoast.showToast(msg: "Senha muito fraca.");
                      } else if (e.code == 'email-already-in-use') {
                        Fluttertoast.showToast(
                            msg: "Este email já está em uso.");
                      } else {
                        Fluttertoast.showToast(
                            msg: "Erro ao criar uma nova conta.");
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                          msg: "Erro ao criar uma nova conta.");
                    }
                  },
                  child: Text(
                    'Entrar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Color.fromARGB(255, 255, 254, 254),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    minimumSize: Size(280, 50),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final GoogleSignInAccount? googleUser =
                        await _googleSignIn.signIn();
                    final GoogleSignInAuthentication googleAuth =
                        await googleUser!.authentication;
                    final AuthCredential credential =
                        GoogleAuthProvider.credential(
                      accessToken: googleAuth.accessToken,
                      idToken: googleAuth.idToken,
                    );
                    await FirebaseAuth.instance
                        .signInWithCredential(credential);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Menu()),
                    );
                  },
                  icon: Image.asset(
                    'images/GoogleIcons.png',
                    width: 30,
                    height: 30,
                  ),
                  label: Row(
                    children: [
                      SizedBox(width: 50),
                      Text(
                        'Continuar Com Google',
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      side: BorderSide(color: Colors.black, width: 1),
                    ),
                    minimumSize: Size(280, 50),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text(
                        "Já tem uma conta?",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const Login()));
                      },
                      child: Text(
                        " Entre",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
