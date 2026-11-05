# NIGHTSHIFT

- Engine validada: Godot 4.0.stable; GDScript. Projeto em `game/`.
- Preserve compatibilidade com Godot 4.0. O renderizador migrou de Compatibility para Forward+ (Vulkan) para o FogVolume do Mêmesis; o preset mobile continua em `gl_compatibility`.
- Leia README.md antes de alterar o projeto. Evite dependências externas no protótipo.
- Não versione `.godot/`, credenciais, builds ou arquivos pessoais.
- Codex e Claude devem trabalhar sequencialmente ou em worktrees separados ao editar código.
- Execute os modos check e test de tools/godot.ps1 após alterações de comportamento.
- Não afirme validação visual, exportação ou testes que não foram executados.

## Colaboração Codex + Claude

- As regras acima valem para os dois agentes. `CLAUDE.md` aponta para este arquivo; mantenha as regras aqui, num lugar só.
- Antes de começar: rode `git status`, leia as entradas recentes de `docs/HANDOFF.md` e confira se há trabalho não commitado de outro agente. Não sobrescreva nem reverta mudanças que você não fez.
- Uma tarefa por vez em cada pasta. Para trabalhar em paralelo, use worktrees/branches separados (`feat/...`) e integre por pull request.
- Ao terminar: acrescente uma entrada no topo de `docs/HANDOFF.md` com arquivos alterados, motivo, o que foi validado de fato (check/test/manual) e o que ficou pendente para o próximo agente.
- O Claude pode não ter Godot nem shell nesta máquina; quando a entrada dele disser "não validado", o próximo agente com acesso ao Godot roda `-Mode check` e `-Mode test` antes de seguir.
