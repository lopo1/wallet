import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinCodeInput extends StatefulWidget {
  final Function(String) onChanged;
  final Function(String) onCompleted;
  final String? Function(String?)? validator;
  final int length;
  final bool obscureText;
  final TextEditingController? controller;

  const PinCodeInput({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.validator,
    this.length = 8,
    this.obscureText = true,
    this.controller,
  });

  @override
  State<PinCodeInput> createState() => _PinCodeInputState();
}

class _PinCodeInputState extends State<PinCodeInput>
    with TickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // 监听外部controller的变化
    if (widget.controller != null) {
      widget.controller!.addListener(_onExternalControllerChanged);
    }

    // 设置初始焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _onExternalControllerChanged() {
    final text = widget.controller?.text ?? '';
    if (text != _currentValue) {
      _updateFromExternalController(text);
    }
  }

  void _updateFromExternalController(String text) {
    setState(() {
      _currentValue = text;
      for (int i = 0; i < widget.length; i++) {
        if (i < text.length) {
          _controllers[i].text = text[i];
        } else {
          _controllers[i].clear();
        }
      }
      _currentIndex = text.length < widget.length ? text.length : widget.length - 1;
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onExternalControllerChanged);
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    setState(() {
      if (value.isNotEmpty) {
        _controllers[index].text = value.substring(value.length - 1);
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        
        if (index < widget.length - 1) {
          _focusNodes[index + 1].requestFocus();
          _currentIndex = index + 1;
        } else {
          _focusNodes[index].unfocus();
          _currentIndex = index;
        }
      } else {
        _controllers[index].clear();
        if (index > 0) {
          _focusNodes[index - 1].requestFocus();
          _currentIndex = index - 1;
        }
      }
      
      _updateCurrentValue();
    });
  }

  void _updateCurrentValue() {
    _currentValue = _controllers.map((c) => c.text).join();
    widget.onChanged(_currentValue);
    widget.controller?.text = _currentValue;
    
    if (_currentValue.length == widget.length) {
      widget.onCompleted(_currentValue);
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          setState(() {
            _currentIndex = index - 1;
          });
          _updateCurrentValue();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.length, (index) {
            return AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                final isCurrentIndex = index == _currentIndex;
                final scale = isCurrentIndex ? _scaleAnimation.value : 1.0;
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 45,
                    height: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focusNodes[index].hasFocus
                            ? const Color(0xFF6366F1)
                            : _controllers[index].text.isNotEmpty
                                ? const Color(0xFF10B981)
                                : Colors.white24,
                        width: _focusNodes[index].hasFocus ? 2 : 1,
                      ),
                      boxShadow: _focusNodes[index].hasFocus
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) => _onKeyEvent(event, index),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.text,
                          maxLength: 1,
                          obscureText: widget.obscureText,
                          obscuringCharacter: '●',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => _onChanged(value, index),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9!@#\$%^&*()_+\-=\[\]{};:"\|,.<>\?]'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        if (widget.validator != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Builder(
              builder: (context) {
                final error = widget.validator!(_currentValue);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: error != null ? 20 : 0,
                  child: error != null
                      ? Text(
                          error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),
      ],
    );
  }
}