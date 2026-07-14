# Plano de Produto e Engenharia — Jogo Mobile de Tabuleiro Imobiliário (nome a definir)

> **Substitui** a spec `2026-04-03-monopoly-mobile-design.md`. Documento sintetizado a partir de análise multi-agente: 4 críticas especializadas (retenção, game design, social/UX, arquitetura), 3 propostas independentes de plano, painel de 3 juízes e auditoria de completude. Mantém os acertos da spec original (Flutter + Riverpod + Freezed + go_router, Supabase, tema de cidades brasileiras, `game_logic.dart` puro, GameState único online/offline, CustomPainter) e substitui a filosofia central.

**Filosofia nova em uma frase:** o benchmark deixa de ser *"paridade com o projeto de 2012"* e passa a ser **"toda sessão termina bem e gera a próxima sessão"**. O jogo de 2012 vira referência de regras-base, não teto de design.

---

## 0. Por que a spec atual não gera engajamento (diagnóstico)

| # | Problema da spec atual | Severidade |
|---|---|---|
| 1 | Partida única de 60–90 min síncrona vs sessão mobile de 7–12 min — D1 destruído pela primeira experiência que o jogador não termina | Crítico |
| 2 | Push notifications excluídas ("YAGNI") — em jogo por turnos, push É o loop de retenção; sem ele não existe D7 | Crítico |
| 3 | Analytics/crashlytics excluídos — impossível medir D1/D7/D30, que são o próprio objetivo; lançamento cego queima a primeira coorte | Crítico |
| 4 | Zero meta-progressão — nada acumula, nada desbloqueia, nenhuma razão de voltar amanhã | Alto |
| 5 | Multiplayer só por código de 6 caracteres digitado — cold start mata o "Play Online" no dia 1 | Alto |
| 6 | Sem convite por link/WhatsApp — o canal de distribuição orgânica do Brasil fica de fora | Alto |
| 7 | Exclusões de regra (leilão, dinheiro em trocas, hipoteca) alongam a partida e esvaziam a negociação — o coração social do jogo | Alto |
| 8 | Cliente do jogador ativo escreve o GameState inteiro sem RLS — anon key extraível do APK = dinheiro infinito, dado escolhido | Alto |
| 9 | Eliminação sem destino + auto-forfeit de 3 min — os dois maiores pontos de churn não tratados | Médio |
| 10 | Spec se chama "Monopoly" — risco jurídico Hasbro/Estrela tratado como nota de rodapé | Bloqueador legal |

---

## 1. Visão e Posicionamento

**Uma frase:** o jogo de tabuleiro imobiliário que o Brasil inteiro conhece, em partidas de 15 minutos que cabem no ônibus, jogadas com os amigos do grupo de WhatsApp — cada partida em uma cidade brasileira.

**Princípios de design (ordem de prioridade em qualquer trade-off):**

1. **Sessão mobile primeiro.** A unidade de diversão é a sessão de 5–20 min, não a partida de 90. Toda partida iniciada termina (por regra, timer ou IA substituta) — nunca morre por abandono.
2. **Negociação é o conteúdo.** Trocas, leilões e zoeira entre amigos são o produto; dados e aluguel são o pretexto.
3. **WhatsApp é o canal.** Cada partida deve gerar pelo menos um convite ou compartilhamento para fora do app.
4. **Brasil é identidade, não skin.** Cidades, bairros e cultura local são mecânica de coleção e progressão, e simultaneamente blindagem jurídica contra o trade dress da Hasbro/Estrela.
5. **Medir ou não existe.** Analytics e crash reporting entram no dia 1.

**Público-alvo do V1:** grupos de amigos/família brasileiros (20–40 anos) que jogavam Banco Imobiliário, coordenam tudo pelo WhatsApp e têm 15 minutos livres, não 90.

### 1.1 Marca (workstream da semana 0 — bloqueia tudo)

- **Proibido:** "Monopoly" (Hasbro), "Banco Imobiliário" (Estrela) e derivados fonéticos. **Nenhum asset da pasta `0620233-0620491/Monopoly/images/` é reaproveitado** (provável derivação de material protegido).
- Candidatos a explorar: *Quarteirão*, *Metrópole!*, *Donos da Cidade*, *Esquina* → busca INPI + App Store/Play + domínio + handles.
- **Parecer de advogado de PI é entregável da semana 0-2 com dono e prazo** — não "antes do listing" (tarde demais). Verificar também colisão de "Sorte/Azar", nomes de casas etc. com registros da Estrela.
- Direção de arte deliberadamente distinta do trade dress clássico: paleta própria, cartas "Sorte/Azar" (não "Sorte/Revés"), "Rodoviária" em vez de "GO/Início" clássico, ilustrações novas.
- Risco distinto do processo: **rejeição por copycat na review da Apple (Guideline 4.1)** — a distância visual protege dos dois.
- Nome define: bundle id (`com.rytech.<nome>`), deep links (`<nome>.app/j/CODIGO`), rename do repo/spec.
- Atenção às brand guidelines da Meta para o botão "Convidar pelo WhatsApp".

---

## 2. Mecânicas de Jogo

### 2.1 Modo Rápido — o padrão do produto (15–25 min)

- Dinheiro inicial: **$1.500**.
- **Setup acelerado:** cada jogador recebe 2 propriedades sorteadas na largada (regra "Speed" oficial — corta os 20 min mais monótonos).
- **Leilão obrigatório** ao recusar compra (2.2).
- **Fim: 12ª rodada completa** (todos jogaram 12 vezes); vence o **maior patrimônio líquido** = `dinheiro + Σ(preço das propriedades) + Σ(casas × housePrice) + hotel × (5 × housePrice)` — exibido em tempo real no PlayerStrip como ranking, para o 2º colocado disputar até a última rodada (mata o runaway leader de graça).
- **Sem eliminação:** falência = propriedades vão a **leilão-relâmpago** entre os demais, jogador volta com $500 e segue disputando patrimônio. **Anti-exploit:** dívida não coberta vira penalidade permanente subtraída do patrimônio final (elimina a "falência estratégica" para proteger patrimônio).
- Cap de tempo no modo ao vivo: 25 min (encerra na rodada corrente).

**Por que Rápido é o padrão e não opção:** 60–90 min vs sessão mobile de 7–12 min é a incompatibilidade que destrói o D1. Nenhuma outra feature compensa uma primeira experiência que o jogador não consegue terminar.

### 2.2 Reversão das três exclusões herdadas de 2012

1. **Leilão ao recusar compra** (`turnPhase: auction`): 25 segundos, todos veem a tela simultaneamente, lance inicial $10 sem mínimo, botões +10/+50/+100/cobrir. Único momento em que todos agem ao mesmo tempo — mata downtime, acelera monopólios (encurta a partida) e gera histórias ("arrematei o Leblon por $80"). Lances concorrentes resolvidos pela RPC server-side (§5).
2. **Dinheiro nas trocas.** UI "balança": arrasta propriedades para cada lado + slider de dinheiro + contra-proposta de 1 toque. Trocas propostas e respondidas **a qualquer momento**, não só no preRoll — espera vira negociação. Sem dinheiro, o espaço de acordos viáveis é tão pequeno que ninguém troca.
3. **Penhora (hipoteca simplificada):** vende ao banco por 50% do preço, recompra por 60% enquanto ninguém comprar (marcada no tabuleiro, sem aluguel). Válvula de comeback contra a espiral de morte.

### 2.3 Decisões de regra explícitas (lacunas da spec fechadas)

- **Duplas:** concedem novo lançamento; 3 duplas seguidas = prisão. Flag `doublesCount`, transição `turnEnd → preRoll` do mesmo jogador. (O original de 2012 só tratava duplas na prisão — documentar a divergência.)
- **Falência no Clássico:** propriedades do falido vão a **leilão entre os sobreviventes**; se a dívida era com um jogador, o credor recebe o produto do leilão até o valor da dívida. (Deliberadamente diferente da regra clássica "credor leva tudo": evita snowball do credor, mantém todos engajados no leilão e compensa o credor.) Casas vendidas ao banco por 50% antes.
- **Turno do eliminado:** passa imediatamente ao próximo vivo (`nextAlivePlayer()`, testada contra off-by-one).
- **Jogador em `debt` que fecha o app:** timer estoura → auto-venda de ativos do menor valor até cobrir; impossível → falência automática. A partida nunca trava.
- **Carta de saída da prisão:** o jogador **escolhe** usar ou guardar (o consumo automático do original é contraintuitivo).
- **Ordem de turno sorteada** com animação de dados de abertura (não join order — elimina vantagem do host e cria micro-ritual).
- **Reshuffle do deck** modelado considerando cartas de prisão que saem e voltam (teste dedicado).
- **Imposto de renda proporcional:** 10% do patrimônio (mín. $100, máx. $400) em vez de $200 fixo — catch-up sutil que pesa no líder.
- **2–3 cartas de Sorte com valores relativos** ("receba $50 por casa construída", "todos pagam $50 a você") — comeback sem distorcer o jogo.
- **Descartado:** salário dobrado nas primeiras rodadas (redundante com o setup Speed).

### 2.4 Ritmo: timer de turno e substituição por IA

- **Timer visível para todos**, escolhido no lobby: Relâmpago 20s / Normal 45s (padrão) / Tranquilo 90s. Auto-ação segura no estouro: rola (preRoll), recusa → leilão (buying), auto-venda mínima (debt), encerra (turnEnd).
- **2 estouros seguidos ou desconexão confirmada (Presence) → IA assume o peão, sempre reversível** — o jogador retoma o controle a qualquer momento ao voltar. Quando resta 1 humano: botão "Encerrar agora" (vence maior patrimônio). Promessa de produto: **partida iniciada, partida terminada.**
- Timeout executado **server-side** (`turn_deadline` + pg_cron/`claim_timeout`), nunca no relógio do cliente.

### 2.5 Micro-engajamento em turno alheio (o defeito nº 1 do gênero: esperar)

- **Palpite do dado:** antes do lançamento alheio, os outros tocam num número (2–12); acerto = +5 XP. Custo: um botão. Efeito: todos assistem a todos os lançamentos.
- **Alerta de tensão:** a UI de todos destaca "se der 6, paga $900 pro João!".
- **Emotes** (§4.2) e **trocas fora do turno** (§2.2) completam o pacote.

### 2.6 Modo Clássico e house rules

- Clássico: $2.458, último solvente vence, eliminação com destino digno (§3.6). Aviso de duração no lobby.
- **House rules brasileiras (V1.1, toggles no lobby):** pote do Estacionamento Grátis (multas acumulam, quem cai leva — a house rule amada no Brasil e injeção de comeback), bônus por parar exato no Início, nº de rodadas do Rápido (8/12/16).

### 2.7 IA com personas (single-player que ensina e retém)

| Persona | Estilo | Ensina |
|---|---|---|
| **Carla, a Negociadora** (V1) | propõe trocas com dinheiro ativamente | negociação — o sistema mais importante |
| **Bia, a Construtora** (update) | compra tudo, constrói rápido | pressão de monopólio |
| **Seu Otávio, o Pão-Duro** (update) | segura caixa, arremata barato | gestão de caixa |

- Avaliação de troca: aceita se `valorRecebido ≥ valorDado × k`; `valor = preço + 40% se completa grupo próprio − 25% se completa grupo do oponente`; `k` = 1,1 / 1,25 / 1,4 (fácil/normal/difícil). Dificuldade = qualidade de avaliação, nunca trapaça de dados.
- **Save/resume obrigatório:** GameState local serializado a cada turno; "Continuar partida" na Home.
- A mesma IA faz double duty: substituta de desconectados e preenchimento de matchmaking.

---

## 3. Loops de Engajamento e Retenção

### 3.1 Onboarding: primeira sessão de 6–8 minutos com vitória

1. **20 segundos de identidade:** apelido + avatar (galeria de 16 avatares ilustrados BR). Sign-in anônimo por baixo, zero cadastro.
2. **"Aprenda jogando":** partida Rápida encurtada (6 rodadas) vs 1 IA fraca, 5 tooltips contextuais (rolar, comprar, aluguel, leilão, construir), balanceada para o jogador **vencer em <8 min** — o momento de competência que ancora o D1.
3. **Funil de saída:** vitória → XP + dois CTAs: "Chamar os amigos" (WhatsApp) e "Jogar Agora".

### 3.2 Push notifications (a feature de maior ROI do produto)

**V1 — 5 tipos:**
1. "É a sua vez em [partida]"
2. "[nome] te convidou para uma partida"
3. "[nome] te propôs uma troca" / "aceitou sua troca" (negociação merece push próprio)
4. "A partida vai começar!"
5. "Revanche? [nome] quer jogar de novo"

- **Opt-in pedido no contexto certo:** logo após a primeira partida online (não no primeiro boot). Meta: **≥60% de opt-in** — métrica de vida ou morte num produto cujo loop é "é sua vez".
- Implementação: `firebase_messaging`, tabela `device_tokens`, Edge Function em trigger de `current_player_id`. ~2–3 dias.
- V1.1: lembrete de turno assíncrono expirando; "suas missões de hoje" **no horário do último uso do jogador** (opt-in separado). Anti-spam: só eventos acionáveis, agrupamento por partida, settings granulares.

### 3.3 Meta-progressão: o tema Brasil como mecânica

Camada fina, nada toca `game_logic.dart` — tabela `player_progress` + telas de perfil/coleção:
- **XP:** terminar 50 / vencer +150 / conquista 25–200 / palpite certo +5. **Nível = `floor(sqrt(XP/100))`**.
- **Desbloqueios:** peões temáticos (bonde de Santa Teresa, jangada, pão de queijo, vira-lata caramelo), tabuleiros de cidades (Rio no launch; SP no primeiro update; Salvador, Recife, Belém, Porto Alegre em diante — bairros reais + 4–6 cartas de sabor local cada).
- **Conquistas com identidade:** "Magnata de Copacabana", "Dono do Pelourinho", "Rei do Leilão", "Primeiro Monopólio", "Fênix" (venceu após quase falir).
- **Stats no perfil:** partidas, vitórias, patrimônio recorde, rival mais frequente, sequência.
- V1 enxuto: XP + níveis + 8 conquistas + 4 peões + tabuleiro Rio.

### 3.4 Missões diárias + streak (V1.1)

3 missões/dia de um pool ("Jogue 1 partida", "Vença um leilão", "Complete um grupo", "Faça uma troca"), **sempre completáveis em 1 sessão**, recompensa XP/cosmético. Streak de dias com marcos 3/7/30 e **perdão automático de 1 dia por semana (streak freeze)** — streak punitivo gera churn, não retenção. Verificação sobre os mesmos eventos do analytics.

### 3.5 Modo assíncrono (V1.1 — a aposta nº 1 pós-launch; infra pronta desde o dia 1)

Estado em Postgres + turnos serializados = jogo por correspondência (modelo Words with Friends) quase de graça: `turn_deadline` 24h, múltiplas partidas simultâneas, Home com lista "Suas partidas" + badge "SUA VEZ", push chama de volta, turno expirado = auto-ação/IA (3 turnos perdidos → IA assume, reversível). **Converte 1 partida em ~15 micro-sessões de 2 min ao longo de dias** — e usa drasticamente menos conexões Realtime (estica o teto do plano do Supabase). O corte do V1 é só a UI de múltiplas partidas; `turn_deadline`, push e persistência já nascem no schema.
- Problema de design em aberto (resolver com playtest antes de codificar): leilão assíncrono — janela de 6h com lances via push vs lance selado único.

### 3.6 Fim de partida e eliminação: nenhuma tela é beco sem saída

- **Fim:** pódio animado com patrimônio → 3 "melhores momentos" extraídos de `game_actions` (maior aluguel pago, quem mais foi preso, virada mais dramática) → XP/conquistas → **"Revanche" (1 toque, mesma mesa, push para todos) + "Compartilhar" (card de imagem com ranking + marca + deep link)**.
- **Eliminado (Clássico):** tela imediata com **XP parcial** + "Assistir" (espectador com emotes — subscription e UI já existem) ou "Jogar outra" (requeue).
- **Conversão da conta anônima no pico emocional:** após a primeira vitória, "Salve seu progresso" → Google/Apple 1 toque via `linkIdentity` (promove anônimo sem perder dados). Sem isso, o meta-game evapora na primeira reinstalação.

### 3.7 Live-ops mínimo (V2)

**"Cidade do mês" com calendário sazonal brasileiro fixo:** Salvador no Carnaval, Recife na Festa Junina, Rio no Réveillon — 1 skin + 1 conquista exclusiva/mês via config remoto. Custa uma skin/mês; dá retorno sazonal e assunto de compartilhamento. ⚠️ Música temática exige licenciamento (ECAD) — usar trilha original/royalty-free.

---

## 4. Social e Crescimento Orgânico no Brasil

### 4.1 Convite WhatsApp-first (o motor de crescimento)

- Botão **"Convidar pelo WhatsApp"** dominante no lobby → share sheet: *"Bora uma partida? Entra na minha sala: https://<nome>.app/j/F7X2K9"*.
- **Universal Links/App Links:** com o app → cai direto no lobby (auto-join); sem o app → **página web de preview da sala** (vê a mesa, quem está nela) → loja.
- **Deferred deep link — decisão técnica fechada** (Firebase Dynamic Links foi descontinuado em 2025): Android = **Play Install Referrer** (oficial, gratuito); iOS = a página de preview **copia o código para o clipboard** + auto-paste no primeiro launch. Sem dependência de Branch/AppsFlyer pagos no V1.
- Fallbacks: código de 6 chars (alfabeto sem 0/O/1/I/L, case-insensitive, auto-paste) + **QR code** na tela do host (churrasco, escritório).
- Entrar por link **não exige cadastro**: anônimo + apelido em 20s.

**Métricas-alvo do funil (instrumentadas do dia 1):** ≥2 convites/sala criada; conversão convite→entrada ≥35% (com código digitado seria <10%); K-factor ≥0,4 no beta; revanche ≥30% das partidas terminadas.

### 4.2 Emotes em vez de chat livre

10 stickers tocáveis a qualquer momento, balão sobre o avatar, sabor BR: "pix caiu", "tô liso", "aluguel, freguês!", risada, "eita", foguinho, mãozinha de negócio, "bora?", choro, palmas. Zero moderação necessária, zero toxicidade, e o jogo ganha voz. Sugestões contextuais em eventos (pagou aluguel caro, foi preso, faliu).

### 4.3 Card de resultado compartilhável

Imagem gerada (ranking + patrimônio + cidade + marca + deep link) direto no share sheet: *"Falei que ia falir geral no Rio. Revanche? <link>"*. Resultado no grupo/Status é convite disfarçado — o recurso viral de melhor custo-benefício.

### 4.4 "Jogar Agora": matchmaking com garantia de início

Regra de ouro: **ninguém espera mais de 60 segundos.** Fila pública de Rápida de 4; se em 45s a mesa não fecha com humanos, **completa com personas de IA** (claramente identificadas como bots — "discretamente marcadas" arrisca reviews "jogo cheio de bot") e começa. Resolve o cold start do dia 1; a proporção humano/bot melhora com a base.

### 4.5 Passa-e-joga (hotseat) — herança direta de 2012

2–6 jogadores no mesmo aparelho, offline. Quase grátis (mesmo GameState local) e forte no Brasil: sem dados móveis, e social presencial. Porta de aquisição: quem joga no celular do amigo conhece o produto.

### 4.6 RivalsScreen (V1.1) — ressurreição por humanos

O grafo social **emerge de `game_players`** (quem jogou com quem), sem friend list formal. Tela "Seus rivais": ranking head-to-head + botão **"Desafiar"** (cria sala + convite direto + push "Fulano te desafiou pra revanche") — o mecanismo de ressurreição de usuário lapsado mais forte do gênero: um humano chamando outro.

### 4.7 Retorno automático à partida

`game_id` ativo persistido localmente; banner "Partida em andamento — Voltar" na Home. Elimina "app morto em background → esqueci o código → forfeit".

### 4.8 Aquisição da primeira coorte (o viral precisa de semente — K<1 não é autossustentável)

- **Grupos-semente:** 10–20 grupos de WhatsApp reais (família, trabalho, faculdade) recrutados pessoalmente para o beta.
- **Creators BR:** micro-influencers de board games/nostalgia no TikTok/Instagram (conteúdo "joguei Banco Imobiliário com minha família à distância").
- Comunidades: Reddit r/jogatina, grupos de board games no Facebook, ProductHunt BR-adjacentes.
- Imprensa de apps/games BR no launch (assessoria zero-custo: press kit + e-mail direto).

---

## 5. Arquitetura Técnica

Mantém: Flutter 3.24+, Riverpod, Freezed + json_serializable, go_router, Supabase, CustomPainter + InteractiveViewer, iOS 15+/Android API 24+.

### 5.1 `GameAction` como sealed class — a espinha dorsal

```dart
@freezed sealed class GameAction {
  // RollDice, BuyProperty, DeclineBuy(→auction), PlaceBid, BuildHouse,
  // SellHouse, PawnProperty, RepurchaseProperty, ProposeTrade, RespondTrade,
  // PayJail, UseJailCard, EndTurn, DeclareBankruptcy, ClaimTimeout, SendEmote,
  // GuessDice
  // Todos carregam actionId (UUID) e expectedVersion.
}
```

`game_logic.dart` vira literalmente `GameState apply(GameState, GameAction)` — puro, fuzzável. O mesmo tipo serializado alimenta: `game_actions`, a validação server-side, as animações (clientes reagem a ações, não a diffs de blob) e o retry idempotente.

### 5.2 Autoridade server-side mínima desde o dia 1

A premissa da spec ("cliente calcula, aceitável") é insustentável: anon key extraível do APK = UPDATE com dinheiro infinito; RNG no cliente = dado escolhido. Um trapaceiro numa mesa de amigos destrói exatamente a confiança social que gera retenção. Correção em três camadas (80% do benefício de Edge Functions por 20% do custo):

1. **RLS estrito:** SELECT só para participantes; UPDATE em `games` **negado a clientes** — toda mutação via RPC `security definer`.
2. **RPC `apply_action(game_id, action jsonb, expected_version, action_id)`** (transacional):
   - `auth.uid()` = jogador da vez (ou ação fora do turno permitida: lance, resposta a troca, emote, palpite);
   - lock otimista real (`expected_version`) + fase do turno compatível;
   - **idempotência:** `action_id` repetido retorna o estado atual sem reaplicar (retry após timeout de rede é rotina em rede móvel);
   - **RNG server-side:** dados e embaralhamento via `gen_random_bytes()` (pgcrypto) — o cliente nunca sorteia o que importa;
   - invariantes baratas: dinheiro ≥ 0 fora de debt, houses 0–5, position 0–39, soma de dinheiro do sistema consistente;
   - grava atomicamente: novo `state` + INSERT em `game_actions` + `version+1`.
   - Cálculo fino continua no cliente no V1; a validação SQL aperta gradualmente guiada pelos test vectors (§5.6).
3. **`claim_timeout`** validado por `now() > turn_deadline` (relógio do servidor); pg_cron como backstop quando todos estão em background.
4. **Rate limiting** nas RPCs e na criação de salas (anon key pública = spam de salas/emotes/XP farming multi-conta). Edge Functions (V1.1+): push, geração do card, turnos de IA server-side no assíncrono, matchmaking.

### 5.3 Realtime: Broadcast from Database, não postgres_changes

Trigger em `games` publica via `realtime.broadcast_changes()` no canal da sala (RLS em `realtime.messages`). Payload = **ação aplicada + version**, não a row inteira — latência menor e estável, muito mais salas por conexão, custo menor (postgres_changes é single-threaded e reenvia o documento completo).

**Regra de reconexão obrigatória:** nem broadcast nem postgres_changes reentregam mensagens perdidas. Em todo resubscribe e em `AppLifecycleState.resumed`: **refetch completo da row antes de reabilitar ações**; `version local < banco` = re-render do zero; UI "sincronizando…" bloqueia ações até confirmar (também previne duplo-tap). App em background = socket caído é o estado **normal** no mobile; Presence distingue "saiu" de "background".

### 5.4 Modelo de dados

```
games           id, room_code, status, mode, rules jsonb, is_public,
                rules_version, config_version, current_player_id (UUID!),
                turn_deadline timestamptz, version int, state jsonb, created_at
game_players    game_id, player_id, seat, is_ai, joined_at      -- o grafo social
game_actions    game_id, seq, actor_id, action jsonb, action_id uuid, created_at  -- append-only
profiles        id, nickname, avatar_id, created_at
player_progress user_id, xp, level, unlocks jsonb, stats jsonb, streak
device_tokens   user_id, token, platform
daily_missions  user_id, date, missions jsonb                    -- V1.1
```

- **Referências por UUID, nunca por índice** (`ownerPlayerId`, `currentPlayerId` + `nextAlivePlayer()`) — elimina a classe de bugs de off-by-one na eliminação.
- **`rules_version` + `config_version` pinados na criação da sala**; cliente incompatível recusa entrar com prompt de update; `min_supported_version` remoto. Sem isso, cada release corrompe partidas com clientes mistos.
- **`board_config` remoto e versionado** (Storage/tabela; cópia embutida como fallback offline) — balanceamento e tabuleiros sazonais sem release de loja.
- **`game_actions` substitui `lastAction: String`:** fonte das animações, log reconstituível na reconexão, replay de debug, auditoria anti-cheat, matéria-prima dos "melhores momentos". **Política de retenção definida:** arquivar/expurgar ações de partidas finalizadas após 90 dias (a tabela cresce sem limite e contém dados de usuário — ver LGPD §8).

### 5.5 Observabilidade

- **Crashlytics ou Sentry desde o primeiro build** — crash aos 50 min = churn invisível; e numa arquitetura onde o cliente ativo calcula, o crash dele afeta a partida dos outros.
- **Firebase Analytics ou PostHog** com ~16 eventos definidos NA SPEC: `app_open`, `onboarding_step`, `room_created`, `invite_shared{canal}`, `join_via_link|code`, `match_start{mode,players,humans}`, `turn_taken{duration}`, `match_end{completed|abandoned,reason,duration}`, `trade_proposed/accepted`, `auction_won`, `rematch`, `result_shared`, `push_optin`, `account_upgraded`, `version_conflict`, `reconnect`.
- Dashboards que decidem o produto: **taxa de conclusão de partidas** (a métrica de saúde nº 1), funil convite→instalação→partida, D1/D7/D30 por coorte e modo, ponto de abandono dentro da partida.

### 5.6 Estratégia de testes

1. Testes puros de `apply(state, action)` para cada regra (o grosso do valor, sem mocks).
2. **Property-based/fuzzing:** sequências aleatórias de ações válidas verificando invariantes (soma de dinheiro consistente, eliminado nunca age, deck pointer válido no reshuffle com cartas de prisão, toda Rápida termina em ≤12 rodadas).
3. **Test vectors dourados** `{estado_antes, ação, seed_rng, estado_depois}` em JSON — gerados pelo Dart, **reexecutados em CI contra as RPCs SQL** (mata mecanicamente a divergência entre as duas implementações).
4. **Simulação IA-vs-IA de milhares de partidas** como gate de CI: terminação (nenhuma fase sem saída) **e balanceamento com alvo explícito — p50 do Modo Rápido ≤ 18 min** como critério de aprovação, não só smoke test.
5. Integração contra **Supabase local (CLI/Docker, migrations no repo):** concorrência (2 clientes, mesma version), retry idempotente, RLS negando escrita fora do turno, leilão com lances simultâneos, claim_timeout.
6. Golden tests do `board_painter`.

### 5.7 Stack (decisões fechadas)

Adiciona à spec: `supabase_flutter`, `firebase_messaging`, `firebase_analytics` + `firebase_crashlytics` (ou `sentry_flutter` + PostHog), `app_links`, `share_plus`, `qr_flutter`. Animação: **Rive** (dados, cartas, leilão — state machines); Lottie dispensado. `mocktail` mantido, mas game_logic se testa sem mocks.

### 5.8 Performance no Brasil real

- **Orçamento de performance:** 60fps do CustomPainter+Rive em Android de entrada (~R$ 700, 2-3GB RAM); matriz mínima de teste: 1 flagship + 2 low-end Android + 1 iPhone antigo (iOS 15).
- **Tamanho de download ≤ 40MB** (dados móveis caros); assets de cidades extras baixados sob demanda.
- Plano de teste em 3G/4G instável (throttling): reconexão, retry idempotente, UI de "sincronizando".

---

## 6. Som, Arte e Game Feel

- **SFX essenciais (V1):** dados, dinheiro entrando/saindo, compra, leilão (tique-taque + martelo), prisão, carta virando, vitória. Haptics leves em eventos-chave. Mute global + ducking.
- **Trilha:** 1 loop leve para menu + 1 para partida, **originais ou royalty-free** (música brasileira conhecida = ECAD/licenciamento — fora do V1).
- **Arte é caminho crítico oculto e entra no cronograma com dono e custo:** 16 avatares, tabuleiro do Rio (40 casas + bairros), 4 peões, ~30 cartas ilustradas, 10 emotes, ícone do app, screenshots da loja. Contratar ilustrador freelancer nas semanas 1–2 (estimativa R$ 8–15 mil; estilo definido junto com a marca). Nenhum asset de 2012 é reutilizado.

---

## 7. Validação com Jogadores Reais (antes e durante o desenvolvimento)

1. **Semana 1 — playtest físico do Modo Rápido:** tabuleiro impresso + planilha, 3-4 sessões com grupos reais. Valida: 12 rodadas são divertidas? O patrimônio como vitória funciona? A regra de falência-recomeço cria exploits? (Simulação IA-vs-IA valida terminação e duração, **não diversão**.)
2. **Semanas 5–6 — teste de usabilidade do onboarding** (5 pessoas, moderado): alguém que nunca viu o app termina a partida guiada sem ajuda?
3. **Semanas 13–16 — beta fechado:** 50–100 pessoas dos grupos-semente (§4.8). Critérios de saída para produção: conclusão de partidas ≥ 60%, crash-free ≥ 99%, push opt-in ≥ 50%, funil de convite instrumentado e funcionando.
4. **Soft launch:** produção com staged rollout (§9) antes de qualquer divulgação.

---

## 8. Legal e Compliance (Brasil + lojas)

- **LGPD:** política de privacidade publicada (obrigatória para as lojas); base legal para analytics/push/device_tokens (legítimo interesse + opt-in de push); dados minimizados (apelido + avatar, sem PII obrigatória); **menores:** jogo family-friendly atrai <13 — anônimo por padrão ajuda, mas o texto da política e o rating devem refletir; retenção/anonimização definidas (expurgo de `game_actions` em 90 dias, §5.4).
- **Exclusão de conta obrigatória** (Apple desde 2022 + Google Play): fluxo in-app que deleta `profiles`, `player_progress`, `device_tokens` e anonimiza `game_actions`/`game_players` (partidas dos outros permanecem íntegras).
- **Classificação indicativa:** questionário IARC no Play + age rating na App Store (dinheiro fictício sem apostas reais → livre; sem simulated gambling declarado errado). ClassInd via IARC.
- **Formulários das lojas:** App Privacy labels (Apple) e Data Safety (Google) coerentes com Firebase/FCM.
- **Termos de uso** simples + código de conduta.
- **Operação de abuso:** filtro de palavrões em apelidos, denúncia de jogador + bloqueio (não jogar de novo com), canal de suporte (e-mail + FAQ na página web).
- **Google Play — closed testing obrigatório para contas pessoais novas:** mínimo de testers por 14 dias antes do acesso à produção — **entra no cronograma** (coincide com o beta fechado).

---

## 9. ASO, Lançamento e Rollout

- **Página da loja:** ícone testado em 3 variantes, 6–8 screenshots com texto sobreposto (primeiro: a mesa com amigos, não o tabuleiro vazio), vídeo preview de 20s, keywords PT-BR ("banco imobiliário online" como termo de busca é legítimo em keywords/ASO — verificação jurídica junto com o parecer da marca), descrição focada em "15 minutos, com amigos, no WhatsApp".
- **In-app review no pico emocional:** prompt nativo após a 2ª vitória ou 1ª revanche — a alavanca orgânica mais barata que existe. Nunca após derrota/crash.
- **Staged rollout:** 10% → 50% → 100% no Play; phased release na App Store. **Kill switch/feature flags** via config remoto (além do config de regras): desligar matchmaking, card, push por tipo sem release.
- **Critério de rollback:** crash-free < 98,5% ou conclusão de partidas caindo >10pp → halt do rollout.
- Resposta a reviews (30 min/dia na primeira quinzena) — sinal de ranking e fonte de bugs.

---

## 10. Roadmap

**Time real declarado:** 1 dev (com Claude Code) + 1 ilustrador freelancer + parecer jurídico pontual. Cronograma honesto: **16 semanas até submissão** (os planos de 10–13 semanas foram julgados irrealistas por 2 dos 3 juízes) + 2–4 semanas de closed testing/review das lojas.

### V1 — "Divertido e retém" (semanas 0–16)

| Semanas | Entrega |
|---|---|
| 0–1 | **Marca** (shortlist → INPI → parecer PI → nome, domínio, bundle id); playtest físico do Modo Rápido; contratação do ilustrador; projeto Flutter + Supabase local + CI + migrations |
| 2–4 | `game_logic.dart` completo (Rápido + Clássico, leilão, trocas com dinheiro, penhora, duplas, patrimônio, imposto proporcional) + fuzzing + test vectors + board_config Rio |
| 5–7 | Board CustomPainter (+ Semantics de acessibilidade), GameScreen, animações essenciais (dado Rive, peão, dinheiro), hotseat + vs IA (Carla) com save/resume; teste de usabilidade do onboarding |
| 8–9 | Supabase online: RPC `apply_action` + RNG server-side + RLS + rate limit + Broadcast + reconexão + timer + IA substituta reversível |
| 10 | Lobby: deep link + WhatsApp + página web de preview + QR + código; sorteio de ordem; "Jogar Agora" com IA |
| 11 | Onboarding (partida guiada), fim de partida (pódio, melhores momentos, revanche 1 toque, card compartilhável), fluxo de eliminado, palpite do dado + alerta de tensão |
| 12 | Push (5 tipos + opt-in contextual), analytics + crashlytics (16 eventos), XP/níveis + 8 conquistas + perfil, upgrade de conta anônima |
| 13 | Emotes, SFX/haptics, exclusão de conta, filtro de apelidos + denúncia, política de privacidade + termos |
| 14–16 | Beta fechado (50–100, grupos-semente) = closed testing do Play; polish guiado pelo funil; ASO (listing completo); submissão |

**Cortes do V1 (com justificativa):** assíncrono → V1.1 (infra pronta; corte é só UI de múltiplas partidas); missões/streak → V1.1 (precisam do pipeline de eventos estável); 2 personas de IA → updates; house rules, espectador por link, tabuleiros além do Rio, RivalsScreen → V1.1/V2.

**Ordem de corte sob pressão (contrato):** emotes → card compartilhável → conquistas. **Nunca cortar:** push, analytics/crashlytics, deep link WhatsApp, leilão, dinheiro nas trocas, modo Rápido, matchmaking com IA, timer + IA substituta, revanche 1 toque, RPC server-side — a análise mostra que são o próprio engajamento.

### V1.1 — "Hábito" (4–6 semanas pós-launch)

Modo assíncrono + "Suas partidas" (a aposta nº 1); missões diárias + streak com freeze; RivalsScreen + "Desafiar"; 2 personas de IA restantes; house rules brasileiras; tabuleiro de SP + coleção completa; espectador por link; iteração guiada pela coorte 1 (ponto de abandono, funil de convite).

### V2 — "Comunidade e temporadas" (contínuo)

Liga mensal entre rivais + card do campeão do grupo; cidade do mês (calendário sazonal fixo); torneios de grupos de WhatsApp (bracket de 8, assíncrono); validação server-side completa (test vectors → SQL) + modos ranqueados; avaliação de **monetização apenas cosmética** (peões, tabuleiros, emotes — nunca vantagem) com critério explícito de introdução: MAU sustentado + D30 > 8%; espanhol/LatAm se a retenção sustentar.

---

## 11. Orçamento (V1, números)

| Item | Custo |
|---|---|
| Apple Developer | US$ 99/ano |
| Google Play Console | US$ 25 (única vez) |
| Supabase | Free no beta → Pro US$ 25/mês no launch |
| Domínio + página web estática | ~R$ 60/ano (Vercel/Cloudflare free) |
| INPI (registro de marca, 1 classe) | ~R$ 355 + honorários R$ 1–3 mil |
| Parecer jurídico PI | R$ 2–5 mil |
| Ilustrador freelancer (pacote V1) | R$ 8–15 mil |
| Firebase (Analytics/Crashlytics/FCM) | Free tier cobre V1 |
| Sentry/PostHog (se usados) | Free tiers cobrem beta |
| **Total V1 aproximado** | **R$ 12–25 mil + ~US$ 150** |

Projeção de infra por escala: Broadcast + assíncrono mantêm o Pro (US$ 25) até dezenas de milhares de MAU; monitorar conexões Realtime e invocações de Edge Functions como métricas de custo.

---

## 12. Riscos

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| **Jurídico: Hasbro/Estrela** (marca, trade dress, assets 2012) | Alta se ignorado | Remoção das lojas | Parecer de PI na semana 0-2 (entregável com dono); zero assets de 2012; arte e nomenclatura distintas; INPI antes do bundle id |
| **Rejeição por copycat (App Store 4.1)** | Média | Atraso de launch | Distância visual deliberada; nome/tema próprios; screenshots sem referência ao clássico |
| **Cold start do multiplayer** | Alta | Mata a razão de ser | IA preenche em 45s; foco em grupos (WhatsApp), não fila pública; hotseat/IA fortes |
| **Funil de convite converte mal** (deferred deep link caseiro) | Média | K < 0,3 | Página de preview + clipboard iOS + Install Referrer Android testados como P0; instrumentação do funil no beta; iterar mensagem/card |
| **Modo Rápido não é divertido** | Média | Retenção do modo padrão | Playtest físico na semana 1 (antes de codificar); config remoto permite rebalancear sem release; gate de CI p50 ≤ 18 min |
| **Escopo estourar** | Alta | Launch atrasado/fraco | Cronograma de 16 semanas já honesto; ordem de corte como contrato; "fora do V1" é contrato |
| **Trapaça/corrupção de estado** | Média | Destrói a confiança do grupo | RLS + RPC + RNG server-side + idempotência no dia 1; `game_actions` como auditoria; test vectors contra divergência |
| **Clientes em versões mistas** | Média | Partidas corrompidas por release | `rules_version`/`config_version` pinados + `min_supported_version` remoto |
| **Push mal calibrado = spam** | Baixa | Opt-out em massa | Só eventos acionáveis; agrupamento; settings granulares; opt-in contextual |
| **Limites Supabase Free/Pro** | Baixa no beta | Teto de crescimento | Broadcast (não postgres_changes); assíncrono usa poucas conexões; upgrade no primeiro sinal |
| **Abuso** (apelidos ofensivos, spam de salas, XP farming) | Média | Reviews negativas | Filtro de nomes, denúncia/bloqueio, rate limiting nas RPCs |
| **Android de entrada com fps ruim** | Média | Churn silencioso no público-alvo | Orçamento de performance + matriz de devices low-end desde a semana 5 |

---

## 13. Métricas de Sucesso (definidas antes do launch)

- **Norte:** partidas concluídas / iniciadas ≥ 70%; D7 ≥ 12% no beta, ≥ 18% pós V1.1.
- **Loop viral:** ≥ 2 convites/sala; conversão convite→entrada ≥ 35%; K ≥ 0,4 (metas a calibrar com o beta — sem benchmark público confiável, o beta é o benchmark).
- **Push:** opt-in ≥ 60%; mediana do turno jogado < 3 min após o push (V1.1/assíncrono).
- **Revanche:** ≥ 30% das partidas geram revanche/nova sala em 24h.
- **Qualidade:** crash-free sessions ≥ 99,5%; zero partidas em estado sem saída (alarme sobre `game_actions`); p50 do Modo Rápido ≤ 18 min em produção.

---

## 14. Resumo executivo das mudanças vs spec de abril

1. **Paridade com 2012 deixa de ser meta** → regras-base + design para sessão mobile.
2. **Modo Rápido (15–25 min, 12 rodadas, patrimônio líquido, sem eliminação) vira o padrão**; Clássico vira opção.
3. **Voltam: leilão, dinheiro nas trocas, penhora, duplas** — as mecânicas sociais e de ritmo. **Entram: imposto proporcional e cartas de comeback.**
4. **Caem as exclusões YAGNI de push e analytics** — são o loop de retenção e o instrumento de voo.
5. **WhatsApp deep link + página de preview + card compartilhável + revanche 1 toque + matchmaking com IA** — o motor de crescimento que a spec não tinha.
6. **Meta-progressão por cidades brasileiras** — o tema vira coleção; assíncrono na V1.1 converte 1 partida em ~15 micro-sessões.
7. **Autoridade server-side mínima no dia 1** (RPC + RLS + RNG server-side + idempotência + `game_actions`), Broadcast em vez de postgres_changes, UUIDs em vez de índices, versionamento de regras/config.
8. **Toda partida iniciada termina; nenhuma tela é beco sem saída.**
9. **O plano agora cobre o negócio, não só o produto:** marca com parecer jurídico na semana 0, LGPD + exclusão de conta + IARC, acessibilidade (Semantics no CustomPainter, padrões além de cor para daltonismo), ASO + in-app review, som/haptics, arte com custo e prazo, playtest humano antes do código, orçamento em números, aquisição da primeira coorte e rollout com kill switch.
10. **Cronograma honesto: 16 semanas + review das lojas, com ordem de corte como contrato.**

---

*Referências: spec original em `docs/superpowers/specs/2026-04-03-monopoly-mobile-design.md` (superseded); regras de referência em `0620233-0620491/Monopoly/src/.../GameController.java`; síntese gerada em 2026-07-13 a partir de análise multi-agente (4 críticos, 3 propostas, 3 juízes, 1 auditor de completude).*
