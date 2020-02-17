import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  final itemController = TextEditingController();
  Map<String, dynamic> _lastRemoved = new Map();
  int _posLastRemoved;

  @override
  void initState() {
    super.initState();
    /**
     * lendo os dados gravados no aplicativo
     * le os dados e depois chama o then
     */
    _readData().then((data) {
      //atualiza a tela
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo['title'] = itemController.text;
      newTodo["ok"] = false;
      itemController.text = "";
      print(newTodo);
      _toDoList.add(newTodo);
      _saveData();
    });
  }

  void _onChangeList(int index, bool marcado) {
    print('mudou lista');
    setState(() {
      _toDoList[index]["ok"] = marcado;
      _saveData();
    });
    // _addTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: head(),
      body: coluna(),
    );
  }

  AppBar head() {
    return AppBar(
      title: Text("Lista de Tarefas"),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }

  Column coluna() {
    return Column(
      children: <Widget>[
        inputDadosAndBTN(),
        Expanded(
            child: RefreshIndicator(
          child: listaDados(),
          onRefresh: _refresh,
        ))
      ],
    );
  }

  Container inputDadosAndBTN() {
    return Container(
      padding: EdgeInsets.fromLTRB(17, 1, 5, 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          //usa o expanded pra usar o maximo possivel da tela
          Expanded(child: inputDados()),
          botaoNovaTarefa(),
        ],
      ),
    );
  }

  ListView listaDados() {
    return ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: _toDoList.length,
        itemBuilder: buildItem);
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b["ok"])
          return 1;
        else if (!a['ok'] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  Widget buildItem(BuildContext context, int index) {
    return
        //slash que faz excluir
        Dismissible(
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            )),
      ),
      child: itemComCheckBox(index),
      // é o nome do elemento q se está excluindo, deve ser único
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      // key: Key(index.toString())
      //qdo se remove o item com o movimento star to end
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _posLastRemoved = index;
          _toDoList.removeAt(index);
          _saveData();
          final SnackBar snack = SnackBar(
            duration: Duration(seconds: 3),
            content: Text("Tarefa ${_lastRemoved["title"]} foi removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_posLastRemoved, _lastRemoved);
                });
              },
            ),
          );
          Scaffold.of(context).removeCurrentSnackBar(); // ADICIONE ESTE COMANDO
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  CheckboxListTile itemComCheckBox(index) {
    return CheckboxListTile(
      title: Text(_toDoList[index]["title"]),
      value: _toDoList[index]["ok"],
      secondary: CircleAvatar(
        child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
      ),
      onChanged: (bool value) {
        _onChangeList(index, value);
      },
      //icone do canto
    );
  }

  TextField inputDados() {
    return TextField(
      controller: itemController,
      decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.blueAccent),
          labelText: "Nova Tarefa"),
    );
  }

  RaisedButton botaoNovaTarefa() {
    return RaisedButton(
      color: Colors.blueAccent,
      child: Text("Add"),
      textColor: Colors.white,
      onPressed: _addTodo,
    );
  }

/// com o path provider o app consegue ter permissio para entrar
/// e gravar nas pastas necessárias do apk
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
    /**
   * data.json é o nome do arquivo onde ficará nossos dados
   * directory é o nome da pasta onde temos acesso
   * File(direc...) é o procedimento de abrir esse doc, como se
   * fosse um cokie
   * */
  }

  Future<File> _saveData() async {
    //pega a lista e transforma em json
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      print("\n\n\n\n\n\n ERROOOOOO" + e);
      return null;
    }
  }
}
