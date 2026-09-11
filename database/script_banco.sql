-- ============================================================
-- Banco de Dados: LavaJato
-- SQL Server LocalDB  |  (localdb)\MSSQLLocalDB
-- Execute no SQL Server Management Studio ou sqlcmd
-- ============================================================

-- Criar o banco 
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'LavaJato')
    CREATE DATABASE LavaJato;
GO

USE LavaJato;
GO

-- TABELAS

/* ============================================================
   TABELA LAVAGENS
   Armazena todas as lavagens realizadas no lava-jato.

   Campos:
   - Id: identificador único da lavagem
   - DataLavagem: data do serviço
   - Cliente: nome do cliente
   - Placa: placa do veículo
   - Servico: tipo de serviço realizado
   - Valor: valor cobrado pela lavagem
============================================================ */

IF OBJECT_ID('Lavagens', 'U') IS NULL
CREATE TABLE Lavagens (
    Id            INT           IDENTITY(1,1) NOT NULL,
    DataLavagem   DATE          NOT NULL,
    Cliente       VARCHAR(100)  NOT NULL,
    Placa         VARCHAR(10)   NOT NULL,
    Servico       VARCHAR(50)   NOT NULL,
    Valor         DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Lavagens PRIMARY KEY (Id)
);
GO




/* ============================================================
   TABELA CUSTOFIXO
   Armazena despesas que não dependem da quantidade de
   veículos lavados.

   Exemplos:
   - Aluguel
   - Salários
   - Água e energia

   O campo MesAno permite registrar os custos de cada mês.
============================================================ */

IF OBJECT_ID('CustoFixo', 'U') IS NULL
CREATE TABLE CustoFixo (
    Id        INT           IDENTITY(1,1) NOT NULL,
    Descricao VARCHAR(100)  NOT NULL,
    Valor     DECIMAL(10,2) NOT NULL,
    MesAno    CHAR(7)       NOT NULL,   -- formato MM/AAAA  ex: 06/2026
    CONSTRAINT PK_CustoFixo PRIMARY KEY (Id),
    CONSTRAINT CK_CustoFixo_MesAno CHECK (MesAno LIKE '[0-1][0-9]/[0-9][0-9][0-9][0-9]')
);
GO


/* ============================================================
   TABELA CUSTOVARIAVEL
   Armazena despesas que aumentam conforme a quantidade
   de lavagens realizadas.

   Exemplos:
   - Produtos de limpeza
   - Comissões
   - Materiais consumidos

   O valor é registrado por lavagem realizada.
============================================================ */

IF OBJECT_ID('CustoVariavel', 'U') IS NULL
CREATE TABLE CustoVariavel (
    Id            INT           IDENTITY(1,1) NOT NULL,
    Descricao     VARCHAR(100)  NOT NULL,
    ValorUnitario DECIMAL(10,2) NOT NULL,   -- valor por carro lavado
    MesAno        CHAR(7)       NOT NULL,   -- formato MM/AAAA
    CONSTRAINT PK_CustoVariavel PRIMARY KEY (Id),
    CONSTRAINT CK_CustoVariavel_MesAno CHECK (MesAno LIKE '[0-1][0-9]/[0-9][0-9][0-9][0-9]')
);
GO

-- Custos Fixos (CF Total = 1.692,00)
INSERT INTO CustoFixo (Descricao, Valor, MesAno) VALUES
    ('Agua/Luz',       350.00, '06/2026'),
    ('Funcionarios',   780.00, '06/2026'),   -- 3 funcionarios x R$ 260,00
    ('Aluguel',        250.00, '06/2026'),
    ('Obrig. Sociais', 312.00, '06/2026');   -- 40% sobre R$ 780,00
GO

-- Custos Variaveis Unitarios (CVU = R$ 4,40 por carro)
INSERT INTO CustoVariavel (Descricao, ValorUnitario, MesAno) VALUES
    ('Materia Prima',  3.00, '06/2026'),   -- produtos quimicos por carro
    ('Comissoes',      1.00, '06/2026'),   -- R$ 1,00 por carro lavado
    ('Obrig. Sociais', 0.40, '06/2026');   -- 40% sobre as comissoes
GO

-- Lavagens de exemplo para junho/2026
-- 20 registros cobrindo o mes todo (PV medio = R$ 12,00)
INSERT INTO Lavagens (DataLavagem, Cliente, Placa, Servico, Valor) VALUES
    ('2026-06-21', 'Leonardo Rocha',    'FGH7890', 'Lavagem Simples',   12.00),
    ('2026-06-03', 'Carla Mendes',      'GHI9012', 'Lavagem Simples',   12.00),
    ('2026-06-20', 'Felipe Andrade',    'WXY5678', 'Lavagem Completa',  20.00),
    ('2026-06-14', 'Amanda Lopes',      'HIJ5678', 'Lavagem Completa',  20.00),
    ('2026-06-05', 'Ricardo Vieira',    'MNO7890', 'Lavagem Detalhada', 35.00),
    ('2026-06-12', 'Beatriz Campos',    'BCD7890', 'Polimento',         50.00),
    ('2026-06-08', 'Diego Farias',      'STU5678', 'Lavagem Completa',  20.00),
    ('2026-06-21', 'Marina Ribeiro',    'ZAB9012', 'Lavagem Simples',   12.00),
    ('2026-06-02', 'Paulo Henrique',    'ABC1234', 'Lavagem Simples',   12.00),
    ('2026-06-16', 'Gabriela Moura',    'NOP3456', 'Lavagem Simples',   12.00),
    ('2026-06-19', 'Rodrigo Nunes',     'QRS7890', 'Lavagem Detalhada', 35.00),
    ('2026-06-10', 'Priscila Costa',    'YZA3456', 'Lavagem Simples',   12.00),
    ('2026-06-07', 'Andressa Martins',  'PQR1234', 'Lavagem Simples',   12.00),
    ('2026-06-20', 'Lucas Almeida',     'TUV1234', 'Lavagem Simples',   12.00),
    ('2026-06-05', 'Julio Cesar',       'JKL3456', 'Lavagem Simples',   12.00),
    ('2026-06-13', 'Renata Freitas',    'EFG1234', 'Lavagem Simples',   12.00),
    ('2026-06-09', 'Mateus Oliveira',   'VWX9012', 'Lavagem Simples',   12.00),
    ('2026-06-15', 'Bianca Cardoso',    'KLM9012', 'Lavagem Simples',   12.00),
    ('2026-06-02', 'Sandra Azevedo',    'DEF5678', 'Lavagem Completa',  20.00),
    ('2026-06-21', 'Thiago Barros',     'CDE3456', 'Lavagem Simples',   12.00);
GO


/* ============================================================
   CÁLCULO FINANCEIRO

   O sistema calcula primeiro a quantidade de lavagens
   realizadas no mês.

   Em seguida soma o valor arrecadado com essas lavagens.

   Depois soma os custos fixos e os custos variáveis.

   Os custos variáveis são calculados multiplicando o
   custo por lavagem pela quantidade de lavagens realizadas.

   Por fim, o sistema subtrai todos os custos do faturamento
   para obter o lucro ou prejuízo do período.
============================================================ */