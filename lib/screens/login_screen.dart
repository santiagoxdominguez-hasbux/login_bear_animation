import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //CONTROL PARA MOSTRAR/OCULTAR CONTRASEÑA
  bool _obscure = true;

  //1.1 CREAR EL CEREBRO DE LA ANIMACION
  StateMachineController? _controller;
  //SMI: STATE MACHINE INPUT / ENTRADA DE MAQUINA DE ESTADO
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'login_bear.riv',
                  stateMachines: const ['Login Machine'],
                  //1.2 vincular animación
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    //1.3 Verificar que inicio bien
                    if (_controller == null) return;
                    //AGREGA EL CONTROLADOR AL ESCENARIO/TABLERO
                    artboard.addController(_controller!);
                    //VINCULAMOS VARIABLES
                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');
                  },
                ),
              ),
              //Para separar espacio
              const SizedBox(height: 10),
              //CAMPO DE TEXTO EMAIL
              TextField(
                onChanged: (value) {
                  if (_isHandsUp != null) {
                    //NO TAPES LOS OJOS
                    _isHandsUp!.change(false);
                  }
                  //SI isChecking es nulo
                  if (_isChecking == null) return;
                  //ACTIVAR EL MODO CHISMOSO
                  _isChecking!.change(true);
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              //CAMPO DE TEXTO CONTRASEÑA
              TextField(
                onChanged: (value) {
                  if (_isChecking != null) {
                    //NO TAPES LOS OJOS
                    _isChecking!.change(false);
                  }
                  //si es ischecking es nulo
                  if (_isHandsUp == null) return;
                  //activar modo chismoso
                  _isHandsUp!.change(true);
                },
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //REFRESCAR EL ICONO
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}