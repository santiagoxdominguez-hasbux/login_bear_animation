import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _rememberMe = false; // Estado del Checkbox
  bool _isAnimating = false; // Bandera Anti-Spam

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

  //4.1 Controllers que manipulan lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //4.2 Errores para mostrarlo en UI
  String? emailError;
  String? passError;

  //4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return re.hasMatch(pass);
  }

  //Función para escuchar el estado de la animación Rive
  void _onRiveStateChange(String stateMachineName, String stateName) {
    // Si la animación vuelve a su estado de reposo (generalmente 'idle' o 'Idle')
    if (stateName.toLowerCase() == 'idle') {
      if (mounted && _isAnimating) {
        setState(() {
          _isAnimating = false; // Liberar la UI
        });
      }
    }
  }

  //4.4 Dar acción al botón
  void _onLogin() {
    // Reto Anti-spam: Si ya está animando, ignorar el clic
    if (_isAnimating) return;

    // Bloquear la UI y comenzar la validación
    setState(() {
      _isAnimating = true;
    });

    //De lo que escribió el usuario, quitar espacios en blanco
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    //4.6 Evaluar los correos
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    //4.7 Avisar que hubo cambios
    setState(() {
      emailError = eError;
      passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus(); //Quita el foco
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.9 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }

    // Temporizador de seguridad: si por alguna razón la animación de Rive
    // no emite el estado 'idle', liberamos la interfaz forzosamente después de 2.5s
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _isAnimating) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

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
      // NUEVO: IgnorePointer para desactivar todo toque en la pantalla mientras anima
      body: IgnorePointer(
        ignoring: _isAnimating,
        child: SingleChildScrollView(
          child: SafeArea(
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
                          // NUEVO: Escuchamos el estado de Rive aquí
                          onStateChange: _onRiveStateChange,
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
                    //4.10 Enlazar controller
                    controller: _emailCtrl,
                    //2.2 Asignar Focu al email
                    focusNode: _emailFocus,
                    onChanged: (value) {
                      if (_isHandsUp != null) {}
                      if (_isChecking == null) return;
                      //ACTIVAR EL MODO CHISMOSO
                      _isChecking!.change(true);
                      //3.6 Implementar numLook
                      final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                      _numLook?.value = look;

                      //3.7 Debounce: si vuelve a teclear, reinicia el contador
                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(const Duration(seconds: 3),(){
                        if (!mounted) return;
                        //Mirada neutra
                        _isChecking?.change(false);
                      });
                    },
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      errorText: emailError, // Agregado el error
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  //CAMPO DE TEXTO CONTRASEÑA
                  TextField(
                    //4.10 Enlazar controller
                    controller: _passCtrl,
                    //2.3 Asignar Focu al campo de texto
                    focusNode: _passwordFocus,
                    onChanged: (value) {
                      if (_isHandsUp == null) return;
                      //activar modo chismoso
                      _isHandsUp!.change(true);
                    },
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      errorText: passError, // Agregado el error
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  //REMEMBER ME
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: Colors.pinkAccent,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      const Text(
                        'Forgot password?',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  //4.13 Boton de login
                  MaterialButton(
                    minWidth: size.width,
                    height: 50,
                    // Cambiar visualmente el botón a un color opaco/gris para dar feedback
                    color: _isAnimating ? Colors.grey : Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Si está animando, devolver null para deshabilitarlo completamente
                    onPressed: _isAnimating ? null : _onLogin,
                    child: _isAnimating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Login', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: (){},
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Colors.black,
                              //subrayado
                              decoration: TextDecoration.underline,
                              //negritas
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose(){
    //4.15 Liberar los controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();
    //2.4 Liberar espacio en memoria
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel(); //3.9 Eliminar el timer
    _controller?.dispose(); // Limpiar el controlador de Rive
    super.dispose();
  }
}