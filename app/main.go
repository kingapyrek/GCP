package main

import (
	"database/sql"
	"encoding/json"
	"log"
	dbFunctions "mymodule/db_conn"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

func mustConnect() *sql.DB {
	var (
		db  *sql.DB
		err error
	)

	// Use a Unix socket when INSTANCE_UNIX_SOCKET (e.g., /cloudsql/proj:region:instance) is defined.
	if os.Getenv("INSTANCE_UNIX_SOCKET") != "" {
		db, err = dbFunctions.ConnectUnixSocket()
		if err != nil {
			log.Fatalf("connectUnixSocket: unable to connect: %s", err)
		}
	}

	if db == nil {
		log.Fatal("Missing database connection type. Please define one of INSTANCE_HOST, INSTANCE_UNIX_SOCKET, or INSTANCE_CONNECTION_NAME")
	}

	_, err = db.Exec("CREATE TABLE IF NOT EXISTS person (name VARCHAR(50), nickname VARCHAR(50))")
	if err != nil {
		log.Fatal("Could't create table person", err)
		panic(err)
	}

	return db
}

type Person struct {
	Name     string `json:"name"`
	Nickname string `json:"nickname"`
}

const (
	host     = "172.17.0.2"
	port     = 5432
	user     = "postgres"
	password = "password"
	dbname   = "postgres"
)

func GETHandler(w http.ResponseWriter, r *http.Request) {
	db := mustConnect()

	rows, err := db.Query("SELECT * FROM person")
	if err != nil {
		log.Fatal(err)
	}

	var people []Person

	for rows.Next() {
		var person Person
		rows.Scan(&person.Name, &person.Nickname)
		people = append(people, person)
	}

	peopleBytes, _ := json.MarshalIndent(people, "", "\t")

	w.Header().Set("Content-Type", "application/json")
	w.Write(peopleBytes)

	defer rows.Close()
	defer db.Close()
}

func POSTHandler(w http.ResponseWriter, r *http.Request) {
	db := mustConnect()

	var p Person
	err := json.NewDecoder(r.Body).Decode(&p)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	sqlStatement := `INSERT INTO person (name, nickname) VALUES ($1, $2)`
	_, err = db.Exec(sqlStatement, p.Name, p.Nickname)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		panic(err)
	}

	w.WriteHeader(http.StatusOK)
	defer db.Close()
}

func DELETEHandler(w http.ResponseWriter, r *http.Request) {
	db := mustConnect()
	r.Method = "DELETE"

	sqlStatement := `DROP TABLE person;`
	_, err := db.Exec(sqlStatement)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		panic(err)
	}
	w.WriteHeader(http.StatusOK)
	defer db.Close()
}

func main() {
	http.HandleFunc("/", GETHandler)
	http.HandleFunc("/insert", POSTHandler)
	http.HandleFunc("/clear", DELETEHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
	log.Print("Serving...")
}
