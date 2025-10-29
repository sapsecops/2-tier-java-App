<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SapSecOps Employee Management</title>
    <style>
        /* Reset default styles */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #f0f4f8, #d9e2ec);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .container {
            background-color: #ffffff;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
            text-align: center;
            max-width: 600px;
            width: 90%;
        }

        h2 {
            color: #333;
            margin-bottom: 30px;
            font-size: 2rem;
            font-weight: 700;
            letter-spacing: 1px;
        }

        .btn {
            display: inline-block;
            padding: 12px 24px;
            margin: 10px;
            font-size: 1.1rem;
            font-weight: 500;
            text-decoration: none;
            color: #fff;
            background-color: #007bff;
            border-radius: 8px;
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
        }

        .btn:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }

        .btn:active {
            transform: translateY(0);
            box-shadow: none;
        }

        .btn.add-employee {
            background-color: #28a745;
        }

        .btn.add-employee:hover {
            background-color: #218838;
        }

        .btn.employee-list {
            background-color: #17a2b8;
        }

        .btn.employee-list:hover {
            background-color: #138496;
        }

        /* Responsive design */
        @media (max-width: 500px) {
            .container {
                padding: 20px;
            }

            h2 {
                font-size: 1.5rem;
            }

            .btn {
                display: block;
                width: 100%;
                margin: 10px 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>SapSecOps Employee Management System</h2>
        <a href="addEmployee.jsp"><button class="btn add-employee">Add Employee</button></a>
        <a href="employeeList"><button class="btn employee-list">Employee List</button></a>
    </div>
</body>
</html>
