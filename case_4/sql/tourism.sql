CREATE DATABASE TourismBooking;
GO

USE TourismBooking;
GO

CREATE TABLE Countries (
    country_id INT PRIMARY KEY IDENTITY(1,1),
    country_name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX)
);

CREATE TABLE Services (
    service_id INT PRIMARY KEY IDENTITY(1,1),
    service_name NVARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

CREATE TABLE Tours (
    tour_id INT PRIMARY KEY IDENTITY(1,1),
    tour_name NVARCHAR(150) NOT NULL,
    country_id INT NOT NULL,
    duration_days INT,
    base_price DECIMAL(10,2),
    description NVARCHAR(MAX),
    CONSTRAINT FK_Tours_Countries FOREIGN KEY (country_id)
        REFERENCES Countries(country_id)
);

CREATE TABLE Clients (
    client_id INT PRIMARY KEY IDENTITY(1,1),
    full_name NVARCHAR(150) NOT NULL,
    phone NVARCHAR(20),
    email NVARCHAR(100),
    registration_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY IDENTITY(1,1),
    client_id INT NOT NULL,
    tour_id INT NOT NULL,
    order_date DATETIME DEFAULT GETDATE(),
    status NVARCHAR(50) DEFAULT N'новый',
    total_price DECIMAL(10,2),
    CONSTRAINT FK_Orders_Clients FOREIGN KEY (client_id)
        REFERENCES Clients(client_id),
    CONSTRAINT FK_Orders_Tours FOREIGN KEY (tour_id)
        REFERENCES Tours(tour_id)
);

CREATE TABLE TourServices (
    tour_id INT NOT NULL,
    service_id INT NOT NULL,
    PRIMARY KEY (tour_id, service_id),
    FOREIGN KEY (tour_id) REFERENCES Tours(tour_id),
    FOREIGN KEY (service_id) REFERENCES Services(service_id)
);

INSERT INTO Countries (country_name, description) VALUES
(N'Россия', N'Экскурсионные туры'),
(N'Турция', N'Пляжный отдых'),
(N'Италия', N'Культурный туризм');

INSERT INTO Services (service_name, price) VALUES
(N'Страховка', 1500),
(N'Трансфер', 3000),
(N'Гид', 5000);

INSERT INTO Tours (tour_name, country_id, duration_days, base_price, description) VALUES
(N'Тур по России', 1, 7, 45000, N'Золотое кольцо'),
(N'Отдых в Турции', 2, 10, 60000, N'All inclusive'),
(N'Италия тур', 3, 8, 85000, N'Рим и Флоренция');

INSERT INTO Clients (full_name, phone, email) VALUES
(N'Иван Иванов', '+79990000000', 'ivan@mail.ru'),
(N'Мария Петрова', '+79991111111', 'maria@mail.ru');
