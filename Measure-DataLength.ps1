#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!DO NOT EXECUTE THIS ON A PROD DATABASE!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!THIS SCRIPT CAN AND PROBABLY WILL CAUSE LOCKING ISSUSES!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!-------------------------------------------------------!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

$SqlFullName = '.'          #=> Sqlserver name can be Server1 or Server1\Instance1
$DbName      = 'WideWorldImporters' #=> Name of the database
$Schema      = 'Application'        #=>  Schema name of the table
$Table       = 'Countries'   #=>  Table name
#==================================================================================================
#Create datatable
#==================================================================================================
$DataTable = New-Object system.Data.DataTable
[void]$DataTable.Columns.Add("schema_name"            , "System.String")
[void]$DataTable.Columns.Add("table_name"             , "System.String")
[void]$DataTable.Columns.Add("column_name"            , "System.String")
[void]$DataTable.Columns.Add("column_datatype"        , "System.String")
[void]$DataTable.Columns.Add("column_defined_max"     , "System.string")
[void]$DataTable.Columns.Add("column_actual_max"      , "System.int64")
[void]$DataTable.Columns.Add("column_percentuage_used", "System.string")
#==================================================================================================
#Get the columns.
#==================================================================================================
#retrieve columns with a collation type => character columns
$Query = "SELECT
            c.[name] AS [column_name],
            st.[name] AS [type_name],
            [max_length]  
          FROM
            [sys].[columns] c INNER JOIN
            [sys].[systypes] st ON st.xtype = c.system_type_id INNER JOIN
            [sys].[tables] t ON c.[object_id] = t.[object_id] INNER JOIN
            [sys].[schemas] sc ON t.[schema_id] = sc.[schema_id]
          WHERE
            sc.[name] = '$Schema' AND
            t.[name]  = '$Table' AND
            collation_name IS NOT NULL"
try
{
     $Columns = Invoke-Sqlcmd -TrustServerCertificate -ServerInstance $SqlFullName -Database $DbName -Query $Query -ErrorAction Stop
}
catch
{
    Throw
}
#==================================================================================================
#Get the max length of value in a column
#==================================================================================================
try
{
  foreach ($Column in  $Columns)
  {
    $ColumnName      = $Column.column_name
    $ColumnDataType  = $Column.type_name
    $ColumnMaxLength = $Column.max_length
    if($ColumnMaxLength -eq -1)
    {
        $ColumnMaxLength = 'max'
    }
    
    $Query            = "SELECT COALESCE(MAX(DATALENGTH([$ColumnName])),0) AS [max_length]  FROM [$Schema].[$Table]"
    $MaxLength        = (Invoke-Sqlcmd -ServerInstance $SqlFullName -Database $DbName -Query $Query -ErrorAction Stop -TrustServerCertificate).max_length
    Switch($ColumnMaxLength)
    {
        'max'   {[string]$PercentUsed = 'Undefined';break} #no used percentage for max columns
        default {$PercentUsed = [math]::Round(($PercentUsed =  100 / $ColumnMaxLength * $MaxLength),2);break}
    }
    [void]$DataTable.Rows.Add($Schema,$Table,$ColumnName,$ColumnDataType,$ColumnMaxLength,$MaxLength,$PercentUsed)
  }
}
catch
{
  throw
}
#==================================================================================================
#Write output to a Grid and to the clipboard
#==================================================================================================
$DataTable | Out-GridView
$DataTable | Set-Clipboard
