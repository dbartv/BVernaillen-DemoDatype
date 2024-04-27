SET STATISTICS IO, TIME ON
USE [DataTypes2022];
/*No Memory grant*/
SELECT TOP (1000) 
	[column_01]  
FROM [DataTypes2022].[dbo].[table_01]
/*Memory grant Sort operator => spill to worktable*/
SELECT TOP (1)
      [column_01]
FROM [DataTypes2022].[dbo].[table_01]
ORDER BY 1
/*Memory grant Hash operator => spill to workfile*/
SELECT DISTINCT 
      [column_01]
FROM [DataTypes2022].[dbo].[table_01]

/*Queries executed during the demo*/
SELECT * FROM [DataTypes2022].[dbo].[table_01] ORDER BY 1
SELECT * FROM [DataTypes2022].[dbo].[table_02] ORDER BY 1
SELECT * FROM [DataTypes2022].[dbo].[table_03] ORDER BY 1
SELECT * FROM [DataTypes2022].[dbo].[table_04] ORDER BY 1
SELECT * FROM [DataTypes2022].[dbo].[table_05] ORDER BY 1


/*Query store plan feedback*/
USE [DataTypes2022];
SELECT qspf.[plan_id],
       [feature_desc],
       [feedback_data] /*1 = CE feedback, 2 = memory grant feedback, 3 = DOP feedback */ ,
       [create_time],
       [last_updated_time],
	   try_convert(xml,[query_plan])
FROM [sys].[query_store_plan_feedback] qspf INNER JOIN 
     [sys].[query_store_plan] qsp ON qsp.[plan_id] = qspf.[plan_id]

/*sys.dm_exec_query_memory_grants*/
SELECT [session_id]
,[request_id]
,[scheduler_id]
,[dop]
,[request_time]
,[grant_time]
,[requested_memory_kb]
,[granted_memory_kb]
,[required_memory_kb]
,[used_memory_kb]
,[max_used_memory_kb]
,[wait_order]
,[is_next_candidate]
,[wait_time_ms]     
,[group_id]
,[pool_id]
,[is_small]
,[ideal_memory_kb]
,[reserved_worker_count]
,[used_worker_count]
,[max_used_worker_count]
,[reserved_node_bitmap]
FROM [master].[sys].[dm_exec_query_memory_grants]
WHERE session_id <> @@SPID
ORDER BY grant_time

/*DBCC queries*/
DBCC IND('DataTypes2022',table_05,-1)
GO
DBCC TRACEON(3604)
DBCC PAGE('DataTypes2022',1,2838,3) WITH TABLERESULTS
GO