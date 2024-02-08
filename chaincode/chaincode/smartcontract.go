package chaincode

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type Bank struct {
	Id           string   `json:"id"`
	Name         string   `json:"name"`
	HQ           string   `json:"hq"`
	FoundingYear int      `json:"foundingYear"`
	PIB          string   `json:"pib"`
	Clients      []string `json:"clients"`
}

type Client struct {
	Id        string   `json:"id"`
	FirstName string   `json:"firstName"`
	LastName  string   `json:"lastName"`
	Email     string   `json:"email"`
	Accounts  []string `json:"accounts"`
}

type Account struct {
	Id       string  `json:"id"`
	Ballance float64 `json:"ballance"`
	Currency string  `json:"currency"`
	//Cards map[string]Card `json:"cards"`
}

// SmartContract provides functions for managing an Asset
type SmartContract struct {
	contractapi.Contract
}

// InitLedger adds a base set of assets to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {

	banks := []Bank{
		{Id: "bank1", Name: "Cacanska banka", HQ: "Cacak", FoundingYear: 1408, PIB: "1408", Clients: []string{}},
		{Id: "bank2", Name: "Kosovska banka", HQ: "Ljubic", FoundingYear: 1389, PIB: "1389", Clients: []string{}},
		{Id: "bank3", Name: "Banka svetog trojstva", HQ: "Cacak", FoundingYear: 333, PIB: "3333", Clients: []string{}},
		{Id: "bank4", Name: "Banka banka", HQ: "Beograd", FoundingYear: 2024, PIB: "2024", Clients: []string{}},
	}

	clients := []Client{
		{Id: "client1", FirstName: "Skabo", LastName: "Maestro", Email: "skabo@gmail.com", Accounts: []string{}},
		{Id: "client2", FirstName: "Raca", LastName: "Braca", Email: "racabraca@gmail.com", Accounts: []string{}},
		{Id: "client3", FirstName: "Milos", LastName: "Obilic", Email: "losmiKralj1389@gmail.com", Accounts: []string{}},
		{Id: "client4", FirstName: "Bosko", LastName: "Jugovic", Email: "jugovicaMother@gmail.com", Accounts: []string{}},
		{Id: "client5", FirstName: "Client5", LastName: "Client5", Email: "Client5@gmail.com", Accounts: []string{}},
		{Id: "client6", FirstName: "Client6", LastName: "Client6", Email: "Client6@gmail.com", Accounts: []string{}},
		{Id: "client7", FirstName: "Client7", LastName: "Client7", Email: "Client7@gmail.com", Accounts: []string{}},
		{Id: "client8", FirstName: "Client8", LastName: "Client8", Email: "Client8@gmail.com", Accounts: []string{}},
		{Id: "client9", FirstName: "Client9", LastName: "Client9", Email: "Client9@gmail.com", Accounts: []string{}},
		{Id: "client10", FirstName: "Client10", LastName: "Client10", Email: "Client10@gmail.com", Accounts: []string{}},
		{Id: "client11", FirstName: "Client11", LastName: "Client11", Email: "Client11@gmail.com", Accounts: []string{}},
		{Id: "client12", FirstName: "Client12", LastName: "Client12", Email: "Client12@gmail.com", Accounts: []string{}},
	}

	accounts := []Account{
		{Id: "account1Eur", Ballance: 1000.0, Currency: "EUR"},
		{Id: "account2Eur", Ballance: 1000.0, Currency: "EUR"},
		{Id: "account3Eur", Ballance: 1000.0, Currency: "EUR"},
		{Id: "account4Eur", Ballance: 1000.0, Currency: "EUR"},
		{Id: "account1Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account2Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account3Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account4Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account5Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account6Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account7Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account8Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account9Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account10Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account11Rsd", Ballance: 1000.0, Currency: "RSD"},
		{Id: "account12Rsd", Ballance: 1000.0, Currency: "RSD"},
	}

	clients[0].Accounts = append(clients[0].Accounts, "account1Eur", "account1Rsd")
	clients[1].Accounts = append(clients[1].Accounts, "account2Eur", "account2Rsd")
	clients[2].Accounts = append(clients[2].Accounts, "account3Eur", "account3Rsd")
	clients[3].Accounts = append(clients[3].Accounts, "account4Eur", "account4Rsd")
	clients[4].Accounts = append(clients[4].Accounts, "account5Rsd")
	clients[5].Accounts = append(clients[5].Accounts, "account6Rsd")
	clients[6].Accounts = append(clients[6].Accounts, "account7Rsd")
	clients[7].Accounts = append(clients[7].Accounts, "account8Rsd")
	clients[8].Accounts = append(clients[8].Accounts, "account9Rsd")
	clients[9].Accounts = append(clients[9].Accounts, "account10Rsd")
	clients[10].Accounts = append(clients[10].Accounts, "account11Rsd")
	clients[11].Accounts = append(clients[11].Accounts, "account12Rsd")

	banks[0].Clients = append(banks[0].Clients, "client1", "client2", "client5")
	banks[1].Clients = append(banks[1].Clients, "client3", "client4", "client6")
	banks[2].Clients = append(banks[2].Clients, "client7", "client8", "client9")
	banks[3].Clients = append(banks[3].Clients, "client10", "client11", "client12")

	for _, bank := range banks {
		bankJSON, err := json.Marshal(bank)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(bank.Id, bankJSON)
		if err != nil {
			return fmt.Errorf("failed to put bank to world state. %v", err)
		}
	}

	for _, client := range clients {
		clientJSON, err := json.Marshal(client)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(client.Id, clientJSON)
		if err != nil {
			return fmt.Errorf("failed to put client to world state. %v", err)
		}
	}

	for _, account := range accounts {
		accountJSON, err := json.Marshal(account)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(account.Id, accountJSON)
		if err != nil {
			return fmt.Errorf("failed to put account to world state. %v", err)
		}
	}

	return nil
}

func (s *SmartContract) GetAllBanks(ctx contractapi.TransactionContextInterface) ([]*Bank, error) {
	//range query works in lexical order
	resultsIterator, err := ctx.GetStub().GetStateByRange("bank1", "bank999")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var banks []*Bank
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var bank Bank
		err = json.Unmarshal(queryResponse.Value, &bank)
		if err != nil {
			return nil, err
		}
		banks = append(banks, &bank)
	}

	return banks, nil
}

// AssetExists returns true when asset with given ID exists in world state
func (s *SmartContract) AssetExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	assetJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return assetJSON != nil, nil
}

// CreateClient issues a new client to the world state with given details.
func (s *SmartContract) CreateClient(ctx contractapi.TransactionContextInterface, id string, firstName string, LastName string, email string) error {
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the client %s already exists", id)
	}

	client := Client{
		Id:        id,
		FirstName: firstName,
		LastName:  LastName,
		Email:     email,
		Accounts:  []string{},
	}
	clientJSON, err := json.Marshal(client)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, clientJSON)
}

// ReadClient returns the client stored in the world state with given id.
func (s *SmartContract) ReadClient(ctx contractapi.TransactionContextInterface, id string) (*Client, error) {
	clientJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if clientJSON == nil {
		return nil, fmt.Errorf("the client %s does not exist", id)
	}

	var client Client
	err = json.Unmarshal(clientJSON, &client)
	if err != nil {
		return nil, err
	}

	return &client, nil
}

// ReadAccount returns the account stored in the world state with given id.
func (s *SmartContract) ReadAccount(ctx contractapi.TransactionContextInterface, id string) (*Account, error) {
	accountJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if accountJSON == nil {
		return nil, fmt.Errorf("the account %s does not exist", id)
	}

	var account Account
	err = json.Unmarshal(accountJSON, &account)
	if err != nil {
		return nil, err
	}

	return &account, nil
}

func (s *SmartContract) AddAcount2Client(ctx contractapi.TransactionContextInterface, clientId string, id string, currency string) error {
	//first check if account already exists
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the account %s already exists", id)
	}

	account := Account{
		Id:       id,
		Ballance: 0.0,
		Currency: currency,
	}

	//then create the account
	accountJSON, err := json.Marshal(account)
	if err != nil {
		return err
	}
	//and push it to world-state
	err = ctx.GetStub().PutState(id, accountJSON)
	if err != nil {
		return err
	}

	//after that get the wanted client
	client, err := s.ReadClient(ctx, clientId)
	if err != nil {
		return err
	}
	//and add the account to him
	client.Accounts = append(client.Accounts, account.Id)
	clientJSON, err := json.Marshal(client)
	if err != nil {
		return err
	}
	//push the updated client to world-state
	return ctx.GetStub().PutState(id, clientJSON)
}

func (s *SmartContract) DepositMoney(ctx contractapi.TransactionContextInterface, id string, ammount float64) error {
	//first check if account actually exists
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists == false {
		return fmt.Errorf("the account %s doesn't exist", id)
	}

	//check if ammount is > 0
	if ammount <= 0 {
		return fmt.Errorf("the ammount must be bigger than 0")
	}

	//after that get the wanted account
	account, err := s.ReadAccount(ctx, id)
	if err != nil {
		return err
	}
	//add the wanted ammount
	account.Ballance += ammount
	accountJSON, err := json.Marshal(account)
	if err != nil {
		return err
	}

	//push the updated account to world-state
	return ctx.GetStub().PutState(id, accountJSON)

}

func (s *SmartContract) WithdrawMoney(ctx contractapi.TransactionContextInterface, id string, ammount float64) error {
	//first check if account actually exists
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists == false {
		return fmt.Errorf("the account %s doesn't exist", id)
	}

	//after that get the wanted account
	account, err := s.ReadAccount(ctx, id)
	if err != nil {
		return err
	}

	//check if account has enough money to make the withdrawal
	if account.Ballance < ammount {
		return fmt.Errorf("The account %s doesn't have enough funds", id)
	}

	//remove the ammount
	account.Ballance -= ammount
	accountJSON, err := json.Marshal(account)
	if err != nil {
		return err
	}

	//push the updated account to world-state
	return ctx.GetStub().PutState(id, accountJSON)
}

func (s *SmartContract) TransferMoney(ctx contractapi.TransactionContextInterface, idAccountFrom string, idAccountTo string, ammount float64) error {
	//check if ammount is > 0
	if ammount <= 0 {
		return fmt.Errorf("The ammount must be greater than 0")
	}

	//read both accounts
	accountFrom, err := s.ReadAccount(ctx, idAccountFrom)
	if err != nil {
		return err
	}
	accountTo, err := s.ReadAccount(ctx, idAccountTo)
	if err != nil {
		return err
	}

	//check if the accounts are of different currency
	if accountFrom.Currency != accountTo.Currency {
		if accountFrom.Currency == "RSD" {
			ammount = ammount / 117
		} else if accountFrom.Currency == "EUR" {
			ammount = ammount * 117
		}
	}

	//check if there's enough money on accountFrom
	if accountFrom.Ballance < ammount {
		return fmt.Errorf("There's not enough money on account for the transfer")
	}

	accountFrom.Ballance -= ammount
	accountTo.Ballance += ammount
	accountFromJSON, err := json.Marshal(accountFrom)
	if err != nil {
		return err
	}
	accountToJSON, err := json.Marshal(accountTo)
	if err != nil {
		return err
	}

	err = ctx.GetStub().PutState(idAccountFrom, accountFromJSON)
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(idAccountTo, accountToJSON)
	if err != nil {
		return err
	}

	return nil
}

//======================================================================
func (s *SmartContract) QueryClientsByFirstName(ctx contractapi.TransactionContextInterface, firstName string) ([]Client, error){
	var result []Client
	searchQuery := strings.ToLower(firstName)
	queryString := fmt.Sprintf(`{
		"selector": {
			"firstName": {"$regex": "(?i)%s"}
		}
	}`, searchQuery)

	queryResults, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("error executing query: %v", err)
	}
	defer queryResults.Close()

	for queryResults.HasNext() {
		value, err := queryResults.Next()
		if err != nil {
			return nil, fmt.Errorf("error reading query result: %v", err)
		}

		var client Client
		err = json.Unmarshal(value.Value, &client)
		if err != nil {
			return nil, fmt.Errorf("error unmarshaling client data: %v", err)
		}

		result = append(result, client)
	}

	return result, nil
}