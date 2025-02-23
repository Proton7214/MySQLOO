TestFramework:RegisterTest("[Transaction] should return added queries correctly", function(test)
	local db = TestFramework:ConnectToDatabase()
	local q1 = db:query("SELECT 1")
	local q2 = db:prepare("SELECT ?")
	q2:setNumber(2, 2)
	local q3 = db:query("SELECT 3")
	local transaction = db:createTransaction()
	test:shouldHaveLength(transaction:getQueries(), 0)
	transaction:addQuery(q1)
	transaction:addQuery(q2)
	transaction:addQuery(q3)
	local queries = transaction:getQueries()
	test:shouldHaveLength(transaction:getQueries(), 3)
	test:shouldBeEqual(queries[1], q1)
	test:shouldBeEqual(queries[2], q2)
	test:shouldBeEqual(queries[3], q3)
	test:Complete()
end)

TestFramework:RegisterTest("[Transaction] run transaction with same query correctly", function(test)
	local db = TestFramework:ConnectToDatabase()
	local transaction = db:createTransaction()
	local qu = db:prepare("SELECT ? as a")
	qu:setNumber(1, 1)
	transaction:addQuery(qu)
	qu:setNumber(1, 3)
	transaction:addQuery(qu)
	function transaction:onSuccess(data)
		test:shouldHaveLength(data, 2)
		test:shouldBeEqual(data[1][1].a, 1)
		test:shouldBeEqual(data[2][1].a, 3)
		test:Complete()
	end
	transaction:start()
	transaction:wait()
end)

TestFramework:RegisterTest("[Transaction] rollback failure correctly", function(test)
	local db = TestFramework:ConnectToDatabase()
	TestFramework:RunQuery(db, [[DROP TABLE IF EXISTS transaction_test]])
	TestFramework:RunQuery(db, [[CREATE TABLE transaction_test(id INT AUTO_INCREMENT PRIMARY KEY)]])
	local transaction = db:createTransaction()
	local qu = db:query("INSERT INTO transaction_test VALUES()")
	local qu2 = db:query("gfdgdg")
	transaction:addQuery(qu)
	transaction:addQuery(qu2)
	function transaction:onError()
		local qu3 = db:query("SELECT * FROM transaction_test")
		qu3:start()
		qu3:wait()
		test:shouldHaveLength(qu3, 0)
		test:Complete()
	end
	transaction:start()
end)