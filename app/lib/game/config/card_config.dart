/// Cartas de Sorte/Azar — adaptadas do jogo de 2012 + cartas de comeback
/// com valores relativos (plano §2.3).
library;

import '../model/cards.dart';

const List<CardDef> rioCards = [
  // ── Sorte ──────────────────────────────────────────────────────────────
  CardDef(id: 1, kind: CardKind.receive, amount: 100, title: 'Herança de um parente distante'),
  CardDef(id: 2, kind: CardKind.receive, amount: 100, title: 'Prêmio no concurso de cachorros'),
  CardDef(id: 3, kind: CardKind.receive, amount: 100, title: 'Você foi promovido no trabalho'),
  CardDef(id: 4, kind: CardKind.receive, amount: 100, title: 'Venceu o torneio de tênis'),
  CardDef(id: 5, kind: CardKind.receive, amount: 150, title: 'O seguro cobriu o assalto'),
  CardDef(id: 6, kind: CardKind.receive, amount: 20, title: 'Acertou no bolão da loteria'),
  CardDef(id: 7, kind: CardKind.receive, amount: 200, title: 'Suas ações na bolsa subiram'),
  CardDef(id: 8, kind: CardKind.receive, amount: 25, title: 'Seu terreno valorizou'),
  CardDef(id: 9, kind: CardKind.receive, amount: 45, title: 'Economizou na diária do hotel'),
  CardDef(id: 10, kind: CardKind.receive, amount: 50, title: '13º salário caiu na conta'),
  CardDef(id: 11, kind: CardKind.receive, amount: 50, title: 'Vendeu bem o carro usado'),
  CardDef(id: 12, kind: CardKind.receive, amount: 80, title: 'Receberam o empréstimo que te deviam'),
  CardDef(id: 13, kind: CardKind.collectFromEach, amount: 50, title: 'Aposta entre amigos: todos pagam você'),
  CardDef(id: 14, kind: CardKind.advanceToStart, title: 'Avance até o Início e receba o salário'),
  CardDef(id: 15, kind: CardKind.freeJail, title: 'Saída livre da prisão'),
  CardDef(id: 16, kind: CardKind.receivePerHouse, amount: 50, title: 'Suas reformas renderam: receba por casa construída'),
  // ── Azar ───────────────────────────────────────────────────────────────
  CardDef(id: 17, kind: CardKind.pay, amount: 100, title: 'Festa de aniversário da família'),
  CardDef(id: 18, kind: CardKind.pay, amount: 100, title: 'Chegou um bebê: enxoval completo'),
  CardDef(id: 19, kind: CardKind.pay, amount: 15, title: 'Parcela do empréstimo venceu'),
  CardDef(id: 20, kind: CardKind.pay, amount: 25, title: 'Mensalidade do clube da piscina'),
  CardDef(id: 21, kind: CardKind.pay, amount: 25, title: 'Mudança para o apartamento novo'),
  CardDef(id: 22, kind: CardKind.pay, amount: 30, title: 'Aula de ballet das crianças'),
  CardDef(id: 23, kind: CardKind.pay, amount: 30, title: 'Multa por estacionar em fila dupla'),
  CardDef(id: 24, kind: CardKind.pay, amount: 30, title: 'IPVA do carro'),
  CardDef(id: 25, kind: CardKind.pay, amount: 40, title: 'Livros novos para a escola'),
  CardDef(id: 26, kind: CardKind.pay, amount: 45, title: 'Fim de semana no hotel da montanha'),
  CardDef(id: 27, kind: CardKind.pay, amount: 45, title: 'Visita dos parentes: churrasco por sua conta'),
  CardDef(id: 28, kind: CardKind.pay, amount: 50, title: 'A geada queimou o café'),
  CardDef(id: 29, kind: CardKind.pay, amount: 50, title: 'Ajuste do imposto de renda'),
  CardDef(id: 30, kind: CardKind.pay, amount: 50, title: 'Mensalidade da escola'),
  CardDef(id: 31, kind: CardKind.goToPrison, title: 'Vá para a prisão!'),
];
