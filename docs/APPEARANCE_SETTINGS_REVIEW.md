# Revisão de Sidebar & Appearance — 2026-10-03

Revisão de cada controle, seu consumidor no código, persistência e dependências.
O build 19 está instalado em `/Applications/WinMuxX.app`, assinado com
`WinMuxX Local Code Signing`, com app e CLI no commit `c0bc117e`. A validação
interativa e as limitações da sessão estão registradas abaixo.

## Problemas corrigidos

1. `Focus sidebar monitor only` descrevia uma função inexistente. `enable-focus`
   apenas inclui o filtro **Focused** no seletor de monitores; agora o rótulo e
   a ajuda dizem isso explicitamente.
2. Auto-hide e Always expanded podiam ficar ligados simultaneamente. Agora há
   uma escolha exclusiva **Sidebar display**: Compact rail, Auto-hide ou Always
   expanded. Os dois valores TOML são validados e salvos em uma única operação.
3. `Tab group padding` não é usado no caminho dos tabs com barra visível. O campo
   foi retirado desta aba; o parâmetro legado continua disponível no TOML.
4. A altura dos tabs oferecia 21–35 pt, mas o renderer exige pelo menos 36 pt.
   O controle agora começa em 36 pt e representa o tamanho efetivo das configs antigas.
5. As paletas apareciam mesmo quando não tinham efeito. Cor sólida aparece em
   Solid color; fundo da sidebar aparece em System; frosted tint aparece somente
   com Transparent. O alcance global do estilo permanece explicitado.
6. Editar um gap podia substituir sua lista de overrides por um número único.
   Agora só altera o padrão, preserva regras por monitor e informa esse alcance.
7. O `@State` da aba não era reconstruído pela identidade aplicada dentro de seu
   próprio body. A identidade agora envolve a view da aba, e reload de config
   atualiza o modelo de Settings. Isso mantém os valores exibidos sincronizados.
8. Paletas não identificavam a configuração responsável por um erro de gravação.
   Agora participam do feedback específico do campo.
9. Os limites de largura respeitam a relação entre compacto e expandido.
   A largura compacta fica indisponível no modo Always expanded.
10. `Menu bar reserve` virou **Top clearance**, com unidade pt. Exclusions de
    bordas foi colocado em um grupo expansível por ser uma configuração avançada.

## Seleção de cores

As duas paletas compartilham amostras circulares com anel de seleção, como o
System Settings. O nome da seleção aparece abaixo, e cada amostra tem tooltip e
identificação para acessibilidade. As cores sólidas ocupam múltiplas linhas para
preservar todos os presets; Custom aparece primeiro como círculo multicolorido.
Os valores TOML são preservados.
A opção Custom continua abrindo o ColorPicker nativo, também usado pelas bordas;
superfícies opacas não oferecem alpha, enquanto bordas mantêm essa possibilidade.
Os controles ficam próximos do elemento afetado para preservar o contexto.

## Item a item

| Item original | Controle e efeito real | Resultado da revisão |
| --- | --- | --- |
| Style | Menu de escolha única; material de tabs, switcher, overlays e sidebar Custom. | Renomeado Surface style, em Window surfaces. Não equivale ao fundo System da sidebar. |
| Solid color | Amostras circulares com anel e nome da seleção. | Mostrar somente em Solid color; mantém escolha anterior ao voltar a Liquid Glass. |
| Custom color | ColorPicker nativo, sem transparência para superfícies opacas. | Manter; aparece quando o preset Custom é selecionado. |
| Show sidebar | Toggle mestre; cria/oculta os painéis nos displays configurados. | Manter; dependentes ficam indisponíveis quando desligado. |
| Sidebar appearance | System usa cores/material macOS; Custom usa o estilo das superfícies. | Manter, com alcance explícito. |
| Sidebar background | Sidebar material, aproximação da menu bar ou Transparent. | Mostrar somente em System. `.sidebar` e `.headerView` são materiais diferentes, embora possam parecer próximos. |
| Expanded frosted tint | Amostras circulares, somente para a sidebar transparente expandida. | Mostrar somente em System + Transparent. Não é a mesma paleta de cor sólida. |
| Focus sidebar monitor only | Na realidade adiciona um filtro de workspaces por display focado. | Corrigido para Show focused-display filter. Não move nem oculta painéis. |
| Reveal sidebar at the display edge | Auto-hide zera a largura em repouso, mantendo ativação pela borda. | Integrado ao menu Sidebar display. |
| Keep sidebar expanded | Expansão persistente; reserva largura na área das janelas. | Integrado ao mesmo menu. A prioridade antiga é preservada ao ler configs com ambos os flags true. |
| Expanded width | Campo numérico + stepper; largura completa do painel. | Manter; limite inferior maior que a largura compacta. |
| Collapsed width | Campo numérico + stepper; largura do rail compacto e área de ativação/drag. | Indisponível em Always expanded. Auto-hide ainda usa essa medida ao revelar o rail. |
| Menu bar reserve | Altura retirada do topo do painel da sidebar. | Renomeado Top clearance; não é o outer top gap das janelas. |
| Show status pills | Liga indicadores de status dentro da sidebar. | Manter, independente do relógio. |
| Show clock | Liga o cartão que contém relógio e calendário. | Manter como mestre dos próximos três itens. |
| Show seconds | Mostra segundos na hora. | Manter; só atua com Show clock. |
| Show date | Mostra dia e mês no cartão. | Manter; não é duplicado de Show weekday. |
| Show weekday | Mostra o dia da semana. | Manter independente de Show date, dependente de Show clock. |
| Show tab strips | Liga a interface de tabs dos grupos de janelas. | Manter; renderer usa a janela ativa e esconde as demais. |
| Tab strip height | Campo numérico + stepper; altura real tem mínimo 36 pt. | Faixa corrigida para 36–80 pt. |
| Tab group padding | Recuo do layout legado sem a interface de tabs visíveis. | Retirado da aba: sua habilitação anterior correspondia ao caminho onde não atua. |
| Inner horizontal | Espaço entre janelas lado a lado. | Manter; editar padrão sem apagar overrides por display. |
| Inner vertical | Espaço entre janelas empilhadas verticalmente. | Manter; mesma preservação. |
| Outer left | Espaço entre sidebar e janelas, ou entre borda da tela e janelas sem sidebar. | Ajuda corrigida para distinguir da largura do painel. |
| Outer right | Recuo das janelas na direita do display. | Manter; não muda o desenho da sidebar. |
| Outer top | Recuo das janelas no topo do display. | Manter; distinto do Top clearance da sidebar. |
| Outer bottom | Recuo das janelas no rodapé do display. | Manter; não altera os cantos ou o rodapé do painel. |
| Show window borders | Liga a decoração de bordas das janelas gerenciadas. | Manter; não é uma borda da sidebar e é suprimido durante Mission Control. |
| Border width | Campo numérico + stepper fracionário; espessura em pt. | Manter. Zero também oculta as bordas; ajuda já explica isso. |
| Focused window color | ColorPicker com opacidade e entrada hexadecimal. | Manter; controles nativos com validação. |
| Other window color | Mesmo controle para janelas não focadas. | Manter; contexto diferente, sem duplicação. |
| Border placement | Menu exclusivo para nível atrás/à frente da janela. | Opções simplificadas para Behind/In front; não é posição interna/externa do traço. |
| Excluded app bundle IDs | Texto validado como lista de IDs separados por vírgula. | Mantido em App exclusions; editor visual de apps pode ser uma melhoria posterior. |

## Aplicação imediata e situações sem efeito visual

Todos os controles mantidos salvam config validada e chamam o mesmo reload.
O reload atualiza o modelo de Settings, atualiza os painéis, atualiza as barras de
tabs e agenda o refresh de layout. Não há botão Apply adicional. As duas flags do
modo de sidebar são aplicadas juntas, evitando um estado intermediário conflitante.

Nem toda opção deve mudar a sidebar: tabs, bordas e gaps atuam principalmente nas
janelas. O estilo global só muda a sidebar em Custom; o tint só atua em Transparent
expandido. Reduce Transparency do macOS pode substituir transparência por um fundo
opaco. Essas dependências explicam parte dos controles que pareciam não disparar.
Não foi atribuída uma falha genérica ao mecanismo de refresh sem reproduzi-la.

## Validação no build instalado

- [x] Abrir Settings e revisar visualmente o layout de Sidebar & Appearance.
- [x] Trocar System/Custom e Glass/Solid; os controles condicionais acompanham a seleção.
- [x] Trocar os três fundos da sidebar e a tonalidade Pink; o painel muda sem reiniciar.
- [x] Selecionar cores sólidas e Custom; o preset mostra nome e amostra e disponibiliza o ColorPicker.
- [x] Trocar Compact rail, Always expanded e Auto-hide; flags persistem conjuntamente.
- [x] Editar a largura expandida de 280 para 320 pt; o painel muda imediatamente.
- [x] Always expanded desabilita o campo de largura compacta.
- [x] Ativar relógio e alterar segundos, data, dia da semana e status pills.
- [x] Alternar Show sidebar, focused-display filter e Show tab strips; valores persistem.
- [x] Alterar config externamente com auto-reload ativo; Settings reflete a configuração.
- [x] Editar o gap padrão de 4 para 6 mantendo overrides main=8 e secondary=12.
- [x] Simular falha de gravação com arquivo temporariamente imutável; Settings mostra
      o erro de permissão e restaura o toggle de bordas ao valor salvo. Bloqueio removido.
- [x] Renderizar e inspecionar prévias de Reduce Transparency e Increased Contrast
      com o renderer real da sidebar, sem mudar a acessibilidade global do macOS.
- [x] Restaurar a configuração original e verificar igualdade byte a byte.

### Limites da validação

- [ ] Verificação visual em dois monitores físicos: `list-monitors` retorna apenas
      Built-in Retina Display nesta sessão. Os overrides foram preservados no arquivo,
      mas o resultado no segundo monitor ainda precisa ser observado.
- [ ] Alternar Reduce Transparency no sistema com o app aberto: nesta sessão foi
      validado o renderer por prévias; não foi testada a mudança global ao vivo.
- [ ] Confirmar a barra de tabs num grupo ativo e os dois seletores nativos de cor de
      borda em interação completa. A alternância dos tabs e a recuperação de erro de
      bordas foram verificadas, mas não equivalem à inspeção visual desses fluxos.

Prévias geradas em `.release/appearance-review-build19/`. Capturas interativas e
relatórios de acessibilidade foram mantidos em `/tmp/winmuxx-*`; contêm dados da
sessão e não foram incluídos no repositório.

## Referências Apple e decisões de interface

- [Settings](https://developer.apple.com/design/human-interface-guidelines/settings): organização em grupos e clareza do alcance das preferências.
- [Toggles](https://developer.apple.com/design/human-interface-guidelines/toggles): configurações booleanas com alvo claramente identificado; escolhas mutuamente exclusivas são representadas por um menu nesta revisão.
- [Color wells](https://developer.apple.com/design/human-interface-guidelines/color-wells): ColorPicker nativo para cores personalizadas e bordas.
- [Color](https://developer.apple.com/design/human-interface-guidelines/color): preservar cores dinâmicas, contraste e comportamento de acessibilidade do sistema.

Ocultar controles sem efeito e agrupar os modos são decisões desta revisão, apoiadas
nesses princípios; não são exigências literais da Apple.

## Verificação

716 testes Swift passaram. Os novos testes verificam a gravação conjunta dos modos e
preservação de overrides de gaps, incluindo monitor principal, secundário, índice e
padrões com aspas. O build foi compilado pela suíte e pelo build Release 19. A assinatura foi
verificada com `codesign --verify --deep --strict`. O app e o CLI em execução
confirmaram o mesmo commit. Os limites da validação visual estão explicitados acima.

## Dimensões da janela de Settings

Em 2026-10-03, a janela Appearance do System Settings nesta máquina manteve a
largura de 757 pt ao tentar reduzi-la ou ampliá-la. O tamanho original era
757 × 818 pt; a altura mínima medida foi 470 pt. Ao pedir altura máxima, o
resultado foi 932 pt na posição original e 1074 pt no topo da área útil do
monitor. Portanto, o máximo vertical observado depende da área útil e da posição,
e não deve ser tratado como uma constante universal da Apple. A janela foi
restaurada ao tamanho e à posição originais após a medição.

WinMuxX agora usa largura de conteúdo fixa de 757 pt, altura inicial de 700 pt e
altura mínima de conteúdo de 470 pt, com redimensionamento vertical. A coluna de
navegação usa largura ideal de 200 pt. Estes ajustes e as amostras circulares são
posteriores ao build 19 instalado.
