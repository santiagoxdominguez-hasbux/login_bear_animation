import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer

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

  //3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  //3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  //2.1 CREAR LAS VARIABLES PARA FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //2.2 Listeners (Oyentes/chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener((){
      if (_emailFocus.hasFocus){
      //Verificar que no sea nulo
        if(_isHandsUp != null){
          //Manos a bajo en el email
         _isHandsUp?.change(false);
         // 3.4 Mirada neutra
         _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener((){
      //Manos arriba
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

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
                  'assets/login_bear.riv',
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
                    //3.5 Vincular numLook
                    _numLook = _controller!.findSMI('numLook');
                  },
                ),
              ),
              //Para separar espacio
              const SizedBox(height: 10),
              //CAMPO DE TEXTO EMAIL
              TextField(
                //2.2 Asignar Focu al email
                focusNode: _emailFocus,
                onChanged: (value) {
                  if (_isHandsUp != null) {
                    //NO TAPES LOS OJOS
                    //_isHandsUp!.change(false);
                  }
                  if (_isChecking == null) return;
                  //ACTIVAR EL MODO CHISMOSO
                  _isChecking!.change(true);
                  //3.6 Implementar numLook
                  //Ajustes de límites del 0 al 100
                  //80 es la medida de calibración
                  final look = (value.length / 60.0 *100.0).clamp(0.0,100.0);
                  //clamp es el rango (abrazadera)
                  _numLook?.value = look;

                  //3.7 Debounce: si vuelve a teclear, reinicia el contador
                  // cancelar cualquier timer existente
                  _typingDebounce?.cancel();
                  //Crear un nuevo timer
                  _typingDebounce = Timer(const Duration(seconds: 3),(){
                    //Si se cierra la pantalla, quita el contador
                    if (!mounted) return;
                    //Mirada neutra
                    _isChecking?.change(false);
                  });
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
                //2.3 Asignar Focu al campo de texto
                focusNode: _passwordFocus,
                onChanged: (value) {
                  if (_isChecking != null) {
                    //NO TAPES LOS OJOS
                    //_isChecking!.change(false);
                  }
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
@override
void dispose(){
  //2.4 Liberar espacio en memoria
  _emailFocus.dispose();
  _passwordFocus.dispose();
  _typingDebounce?.cancel(); //3.9 Eliminar el timer
  super.dispose();
}
}