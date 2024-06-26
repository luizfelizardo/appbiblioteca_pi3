import 'package:biblioteca_modular/models/curso_aluno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../models/aluno.dart';
import '../../../models/curso.dart';
import '../../../repositories/database_repository.dart';

class MatriculaPage extends StatefulWidget {
  const MatriculaPage({super.key, required this.aluno});

  final Aluno aluno;

  @override
  State<MatriculaPage> createState() => _MatriculaPageState();
}

class _MatriculaPageState extends State<MatriculaPage> {
  final DatabaseRepository _databaseRepository =
      Modular.get<DatabaseRepository>();
  List<Curso> cursos = [];
  List<Map<String, dynamic>> cursosMatriculados = [];
  List<Map<String, dynamic>> qtdAlunosPorCurso = [];

  @override
  void initState() {
    _getCursos();
    _getCursoAlunos();
    _getQtdAlunosPorCurso();
    super.initState();
  }

  void _getCursos() {
    _databaseRepository.getCursos().then((value) {
      setState(() {
        cursos = value;
      });
    });
  }

  void _getCursoAlunos() {
    _databaseRepository
        .getCursosMatriculados(widget.aluno.codigo!)
        .then((value) {
      setState(() {
        cursosMatriculados = value;
      });
    });
  }

  void _getQtdAlunosPorCurso() {
    _databaseRepository.getQtdAlunosPorCurso().then((value) {
      setState(() {
        qtdAlunosPorCurso = value;
      });
    });
  }

  bool _verifiInscricao(int codigo) {
    for (var map in cursosMatriculados) {
      if (map.containsValue(codigo)) {
        return true;
      }
    }
    return false;
  }

  Text _verificaQtdInscritos(int index) {
    if (qtdAlunosPorCurso.isNotEmpty) {
      if (qtdAlunosPorCurso[index]['qtd_inscritos'] < 2) {
        return const Text(
          'disponível',
          style:
              TextStyle(fontSize: 15, color: Color.fromARGB(255, 83, 212, 23)),
        );
      } else if (qtdAlunosPorCurso[index]['qtd_inscritos'] == 2) {
        return const Text(
          'emprestado',
          style:
              TextStyle(fontSize: 15, color: Color.fromARGB(255, 212, 11, 11)),
        );
      } else {
        return const Text('');
      }
    }
    return const Text('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' ${widget.aluno.nome}'),
      ),
      body: ListView.builder(
        itemCount: cursos.length,
        itemBuilder: (context, index) {
          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              cursos[index].descricao,
              style: const TextStyle(fontSize: 20),
            ),
            subtitle: _verificaQtdInscritos(index),
            value: _verifiInscricao(cursos[index].codigo!),
            onChanged: (val) {
              if (_verifiInscricao(cursos[index].codigo!)) {
                _databaseRepository.deleteCursoAlunos(
                    widget.aluno.codigo!, cursos[index].codigo!);
              } else {
                if (qtdAlunosPorCurso[index]['qtd_inscritos'] < 2) {
                  if (cursosMatriculados.length == 3) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "${widget.aluno.nome} já tem emprestimo de 3 livros",
                        textAlign: TextAlign.center,
                      ),
                    ));
                  } else {
                    CursoAluno cursoAluno = CursoAluno(
                        codigoAluno: widget.aluno.codigo!,
                        codigoCurso: cursos[index].codigo!);
                    _databaseRepository.insertCursoAlunos(cursoAluno);
                  }
                } else if (qtdAlunosPorCurso[index]['qtd_inscritos'] >= 1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                      "Livro emprestado!",
                      textAlign: TextAlign.center,
                    ),
                  ));
                }
              }

              _getCursoAlunos();
              _getQtdAlunosPorCurso();
            },
          );
        },
      ),
    );
  }
}
