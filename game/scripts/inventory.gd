extends RefCounted
# The checkpoint flags are the source of truth: no second, divergent item store.
static func entries(chapter: Node) -> Array:
	var result := []
	var catalog := [
		["badge","Crachá e chave de serviço","ACESSO","Daniel Reis • Vigilância noturna. Acesso à segurança e às áreas autorizadas pelo plantão."],
		["flashlight","Lanterna","EQUIPAMENTO","Lanterna de mão. F liga e desliga; permanece disponível durante as falhas de energia."],
		["personnel_key","Chave de pessoal","CHAVE","Etiqueta: PESSOAL / 2º. Utilizada automaticamente ao abrir a porta da sala de pessoal."],
		["it_key","Chave do armário TI","CHAVE","Etiqueta: TI / PEÇAS. Utilizada automaticamente na fechadura do armário da sala de TI."],
		["fuse20_owned","Cartucho 20 A","MANUTENÇÃO","Reposição F1. Instale no suporte do quadro com todos os circuitos isolados."],
		["fuse10_owned","Cartucho 10 A","MANUTENÇÃO","Calibre incompatível com F1. A ordem de manutenção especifica a reposição correta."]]
	for item in catalog:
		if chapter.has_flag(item[0]): result.append(item)
	if chapter.has_flag("burnt_fuse_removed") and not chapter.has_flag("fuse_replaced"):
		result.append(["burnt_fuse","Cartucho queimado","EVIDÊNCIA","Filamento interrompido. Removido do suporte F1; não pode ser reinstalado."])
	return result
