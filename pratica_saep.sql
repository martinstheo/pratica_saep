    INSERT INTO historico_tarefas (id_tarefa, acao, detalhes)
    VALUES (
        NEW.id_tarefa,
        'Tarefa criada',
        'Tarefa "' || NEW.titulo || '" cadastrada com status: ' || NEW.status
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico_tarefa();

INSERT INTO tarefas
(titulo, descricao, id_categoria, id_colaborador, data_agendamento, prazo_entrega, status)
VALUES
('Criar página inicial', 'Desenvolver a tela inicial do sistema', 1, 1,
 CURRENT_DATE, CURRENT_DATE + 5, 'Em andamento'),
('Elaborar documentação', 'Documentar os requisitos do projeto', 2, 2,
 CURRENT_DATE + 1, CURRENT_DATE + 7, 'Pendente'),
('Planejar reunião semanal', 'Organizar os assuntos da equipe', 3, 1,
 CURRENT_DATE + 2, CURRENT_DATE + 3, 'Pendente');

CREATE OR REPLACE FUNCTION fn_buscar_colaboradores(p_termo TEXT)
RETURNS TABLE (
    id_colaborador INT,
    nome VARCHAR(100),
    email VARCHAR(150),
    ativo BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id_colaborador, c.nome, c.email, c.ativo
      FROM colaboradores AS c
     WHERE c.nome ILIKE '%' || COALESCE(p_termo, '') || '%'
        OR c.email ILIKE '%' || COALESCE(p_termo, '') || '%'
     ORDER BY c.nome;
END;
$$;

CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT
    c.nome AS colaborador,
    t.titulo AS tarefa,
    cat.nome AS categoria,
    t.prazo_entrega,
    t.status
FROM tarefas AS t
INNER JOIN colaboradores AS c
        ON c.id_colaborador = t.id_colaborador
INNER JOIN categorias AS cat
        ON cat.id_categoria = t.id_categoria;

CREATE OR REPLACE VIEW vw_cronograma_prazos AS
SELECT
    t.id_tarefa,
    t.titulo,
    t.data_agendamento,
    t.prazo_entrega,
    t.status,
    (t.prazo_entrega - CURRENT_DATE) AS dias_restantes,
    c.nome AS responsavel
FROM tarefas AS t
INNER JOIN colaboradores AS c
        ON c.id_colaborador = t.id_colaborador
ORDER BY t.prazo_entrega ASC, t.data_agendamento ASC, t.id_tarefa ASC;

--conferir os codigos

SELECT * FROM vw_painel_principal;

SELECT * FROM vw_cronograma_prazos
ORDER BY prazo_entrega ASC, data_agendamento ASC, id_tarefa ASC;

SELECT * FROM fn_buscar_colaboradores('ana');

SELECT * FROM historico_tarefas ORDER BY data_registro, id_historico;

SELECT 'colaboradores' AS tabela, COUNT(*) AS quantidade FROM colaboradores
UNION ALL
SELECT 'categorias', COUNT(*) FROM categorias
UNION ALL
SELECT 'tarefas', COUNT(*) FROM tarefas
UNION ALL
SELECT 'historico_tarefas', COUNT(*) FROM historico_tarefas;
