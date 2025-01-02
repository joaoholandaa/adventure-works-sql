# === Relatório 1: Vendas mensais === #
-- Pergunta: Qual é a receita da empresa em cada mês? --
SELECT 
	EXTRACT(YEAR FROM OrderDate) AS AnoPedido,
	EXTRACT(MONTH FROM OrderDate) AS MesPedido,
	ROUND(SUM(TotalDue), 2) AS ReceitaTotal
FROM sales_salesorderheader
GROUP BY
	EXTRACT(YEAR FROM OrderDate),
	EXTRACT(MONTH FROM OrderDate)
ORDER BY
	AnoPedido DESC,
	MesPedido DESC;

# === Relatório 2: Receita mensal por país === #
-- Pergunta: Qual é a receita mensal de cada país? --
SELECT 
	cr.Name AS Pais,
	EXTRACT(YEAR FROM OrderDate) AS AnoPedido,
	EXTRACT(MONTH FROM OrderDate) AS MesPedido,
	ROUND(SUM(TotalDue), 2) AS ReceitaTotal
FROM sales_salesorderheader soh
JOIN sales_salesterritory st
	ON soh.TerritoryID = st.TerritoryID
JOIN person_countryregion cr
	ON cr.CountryRegionCode = st.CountryRegionCode
GROUP BY
	cr.Name,
	EXTRACT(YEAR FROM OrderDate),
	EXTRACT(MONTH FROM OrderDate)
ORDER BY
	AnoPedido DESC,
	MesPedido DESC,
	Pais;
    
# === Relatório 3: Produtos mais vendidos === #
-- Pergunta: Quais são os nossos produtos mais vendidos?
SELECT 
	p.ProductID,
	p.Name AS NomeProduto,
    SUM(od.OrderQty) AS TotalUnidadesVendidas
FROM sales_salesorderdetail od
JOIN production_product p
	ON od.ProductID = p.ProductID
GROUP BY 
	p.Name, 
    p.ProductID
ORDER BY TotalUnidadesVendidas DESC
LIMIT 10;

# === Relatório 4: Lojas com melhor desempenho === #
-- Pergunta: Quais são as 10 principais lojas por vendas nos últimos dois meses?
SELECT
  COALESCE(s.Name, 'Online') AS NomeLoja,
  ROUND(SUM(so.TotalDue), 2) AS ValorTotalVendas
FROM sales_salesorderheader so
LEFT JOIN sales_store s
  ON so.SalesPersonID = s.SalesPersonID
GROUP BY s.Name
ORDER BY ValorTotalVendas DESC
LIMIT 10;

# === Relatório 5: Fontes de receita === #
-- Questão: Como a receita on-line se compara à receita off-line?
SELECT
  CASE WHEN OnlineOrderFlag THEN 'Online' ELSE 'Store' END AS PedidoOrigem,
  COUNT(SalesOrderId) AS TotalVendas,
  SUM(TotalDue) AS ReceitaTotal
FROM sales_salesorderheader
GROUP BY OnlineOrderFlag
ORDER BY ReceitaTotal DESC;

# == Relatório 6: Tamanho médio do pedido por país == #
-- Pergunta: Qual é o tamanho médio do pedido?
WITH PedidosTamanhos AS (
  SELECT
    sod.SalesOrderId,
    SUM(OrderQty) AS ProductCount,
    cr.Name AS Country
  FROM sales_salesorderheader soh
  JOIN sales_salesorderdetail sod
    ON sod.SalesOrderID = soh.SalesOrderID
  JOIN sales_salesterritory st
    ON soh.TerritoryID = st.TerritoryID
  JOIN person_countryregion cr
    ON cr.CountryRegionCode = st.CountryRegionCode
  GROUP BY
    sod.SalesOrderID,
    cr.Name
)
SELECT
  Country AS País,
  ROUND(AVG(ProductCount), 2) AS MediaTamanhoPedido
FROM PedidosTamanhos
GROUP BY Country
ORDER BY MediaTamanhoPedido DESC;

# == Relatório 7: Valor médio vitalício do cliente por região == #
-- Pergunta: Qual é o valor médio da vida útil do cliente em cada região?
WITH ReceitaVitaliciaCliente AS (
  SELECT
    cstm.CustomerID,
    ord.TerritoryID,
    SUM(TotalDue) AS ReceitaVitalicia
  FROM sales_Customer cstm
  JOIN sales_salesorderheader ord
    ON cstm.CustomerID = ord.CustomerID
  GROUP BY
    cstm.CustomerID,
    ord.TerritoryID
)
SELECT
  cr.Name AS País,
  ROUND(AVG(rvc.ReceitaVitalicia),2) AS ValorMedioDoClienteAoLongoDaVida
FROM ReceitaVitaliciaCliente rvc
JOIN sales_salesterritory tr
  ON rvc.TerritoryID = tr.TerritoryId
JOIN person_countryregion cr
  ON cr.CountryRegionCode = tr.CountryRegionCode
GROUP BY cr.Name
ORDER BY
  ValorMedioDoClienteAoLongoDaVida DESC,
  cr.Name;