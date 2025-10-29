<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Employee</title>
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
            padding: 20px;
        }

        .container {
            background-color: #ffffff;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
            max-width: 600px;
            width: 90%;
        }

        h2 {
            color: #333;
            margin-bottom: 30px;
            font-size: 2rem;
            font-weight: 700;
            text-align: center;
            letter-spacing: 1px;
        }

        form {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        label {
            font-size: 1.1rem;
            color: #333;
            font-weight: 500;
        }

        input[type="text"],
        input[type="email"],
        input[type="number"],
        input[type="hidden"] {
            width: 100%;
            padding: 12px;
            font-size: 1rem;
            border: 1px solid #ccc;
            border-radius: 8px;
            transition: border-color 0.3s ease;
        }

        input[type="text"]:focus,
        input[type="email"]:focus,
        input[type="number"]:focus {
            outline: none;
            border-color: #007bff;
            box-shadow: 0 0 5px rgba(0, 123, 255, 0.3);
        }

        input[type="submit"] {
            padding: 12px;
            font-size: 1.1rem;
            font-weight: 500;
            color: #fff;
            background-color: #17a2b8;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        input[type="submit"]:hover {
            background-color: #138496;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }

        input[type="submit"]:active {
            transform: translateY(0);
            box-shadow: none;
        }

        .back-link {
            display: inline-block;
            margin-top: 20px;
            font-size: 1rem;
            color: #007bff;
            text-decoration: none;
            transition: color 0.3s ease;
        }

        .back-link:hover {
            color: #0056b3;
            text-decoration: underline;
        }

        /* Responsive design */
        @media (max-width: 500px) {
            .container {
                padding: 20px;
            }

            h2 {
                font-size: 1.5rem;
            }

            input[type="text"],
            input[type="email"],
            input[type="number"],
            input[type="submit"] {
                font-size: 0.9rem;
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Edit Employee</h2>
        <form action="editEmployee" method="post">
            <input type="hidden" name="id" value="${employee.id}">
            <label for="name">Name:</label>
            <input type="text" id="name" name="name" value="${employee.name}" required>
            <label for="email">Email:</label>
            <input type="email" id="email" name="email" value="${employee.email}" required>
            <label for="designation">Designation:</label>
            <input type="text" id="designation" name="designation" value="${employee.designation}" required>
            <label for="salary">Salary:</label>
            <input type="number" id="salary" step="0.01" name="salary" value="${employee.salary}" required>
            <input type="submit" value="Update Employee">
        </form>
        <a href="index.jsp" class="back-link">Back to Home</a>
    </div>
</body>
</html>
