# PolCarZadania
Zadanie rekrutacyjne PolCar
W zadaniu założyłem, że pomiędzy użytkownikiem a bazą danych jest dodatkowa warstwa do komunikacji, 
która przekazywałaby parametr id_user lub id_tenant z sesji.

W projekcie użyłem koncepcji wielu tenantów. 

Do kluczowych(wg mnie) tabel zostały stworzone indexy na kolumnie tenant_id.

Skrypt może zająć kilka minut do ukończenia.

Stworzone obiekty bazodanowe:
Tabele:
	-_tb_tenants - podmiotyy
	-_tb_users - użytkownicy
	-_tb_users_managers - relacja menedżer - użytkownik
	-_tb_status - statusy
	-_tb_priorities - priorytety
	-_tb_tasks - zadania
	-_tb_tasks_histo - historia zadań
	-_tb_tasks_users - relacja udostępnione zadanie - użytkownik

Procedury i funkcje(króktie opisy w skrypcie):
	-dbo._sp_show_tasks
	-dbo.udfTasksSecurity
	-dbo._sp_delete_task
	-dbo._sp_update_task
	-dbo._sp_create_task
	-dbo._sp_manager_statistics
Indexy:
	-idx_tasks_histo_tenant ON _tb_tasks_histo 
	-idx_tasks_tenant ON _tb_tasks 

Dołożyłbym jeszcze audyt procedur w razie błędów.

Zabrakło mi czasu, żeby dołożyć logikę która pozwoliłaby użytkownikowi udostępniać zadania albo edytować komu te zadania są udostępnione.
Myślę, że osobne procedury lub zawarcie logiki w istniejących procedurach.

Brak logiki do usuwania lub deaktywacji userów.
