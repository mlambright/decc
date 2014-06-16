SELECT clients.org_name AS 'Client', types.type_name, orders.idorders, orders.order_date AS 'Order Date', sum(batches.final_item_count) AS 'Count', types.cost_rate AS 'Rate', sum(batches.final_item_count) * types.cost_rate AS 'Total', types.cost_to_noi AS 'Cost', sum(batches.final_item_count) * types.cost_to_noi AS 'TotalCost'
FROM decc.clients
INNER JOIN decc.projects
ON clients_idclients = clients.idclients
INNER JOIN decc.orders
ON projects_idprojects = projects.idprojects
INNER JOIN decc.parts
ON orders_idorders = orders.idorders
INNER JOIN decc.types
ON parts.types_idtypes = types.idtypes
INNER JOIN decc.batches
ON parts.idpieces = parts_idparts
GROUP BY clients.org_name, types.type_name, orders.order_date, types.cost_rate
ORDER BY orders.order_date;