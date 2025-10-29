package com.employeemanagement.dao;

import com.employeemanagement.model.Employee;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class EmployeeDAO {
    private String jdbcURL;
    private String jdbcUsername;
    private String jdbcPassword;
    private Connection jdbcConnection;

    public EmployeeDAO() {
        try {
            Properties props = new Properties();
            props.load(getClass().getClassLoader().getResourceAsStream("application.properties"));
            this.jdbcURL = props.getProperty("spring.datasource.url");
            this.jdbcUsername = props.getProperty("spring.datasource.username");
            this.jdbcPassword = props.getProperty("spring.datasource.password");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected void connect() throws SQLException {
        if (jdbcConnection == null || jdbcConnection.isClosed()) {
            try {
                Class.forName("org.postgresql.Driver");
            } catch (ClassNotFoundException e) {
                throw new SQLException(e);
            }
            jdbcConnection = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
        }
    }

    protected void disconnect() throws SQLException {
        if (jdbcConnection != null && !jdbcConnection.isClosed()) {
            jdbcConnection.close();
        }
    }

    public void addEmployee(Employee employee) throws SQLException {
        String sql = "INSERT INTO employee (name, email, designation, salary) VALUES (?, ?, ?, ?)";
        connect();

        PreparedStatement statement = jdbcConnection.prepareStatement(sql);
        statement.setString(1, employee.getName());
        statement.setString(2, employee.getEmail());
        statement.setString(3, employee.getDesignation());
        statement.setDouble(4, employee.getSalary());

        statement.executeUpdate();
        statement.close();
        disconnect();
    }

    public List<Employee> listAllEmployees() throws SQLException {
        List<Employee> listEmployee = new ArrayList<>();
        String sql = "SELECT * FROM employee";
        connect();

        Statement statement = jdbcConnection.createStatement();
        ResultSet resultSet = statement.executeQuery(sql);

        while (resultSet.next()) {
            int id = resultSet.getInt("id");
            String name = resultSet.getString("name");
            String email = resultSet.getString("email");
            String designation = resultSet.getString("designation");
            double salary = resultSet.getDouble("salary");

            Employee employee = new Employee(id, name, email, designation, salary);
            listEmployee.add(employee);
        }

        resultSet.close();
        statement.close();
        disconnect();
        return listEmployee;
    }

    public Employee getEmployee(int id) throws SQLException {
        Employee employee = null;
        String sql = "SELECT * FROM employee WHERE id = ?";
        connect();

        PreparedStatement statement = jdbcConnection.prepareStatement(sql);
        statement.setInt(1, id);

        ResultSet resultSet = statement.executeQuery();

        if (resultSet.next()) {
            String name = resultSet.getString("name");
            String email = resultSet.getString("email");
            String designation = resultSet.getString("designation");
            double salary = resultSet.getDouble("salary");

            employee = new Employee(id, name, email, designation, salary);
        }

        resultSet.close();
        statement.close();
        disconnect();
        return employee;
    }

    public void updateEmployee(Employee employee) throws SQLException {
        String sql = "UPDATE employee SET name = ?, email = ?, designation = ?, salary = ? WHERE id = ?";
        connect();

        PreparedStatement statement = jdbcConnection.prepareStatement(sql);
        statement.setString(1, employee.getName());
        statement.setString(2, employee.getEmail());
        statement.setString(3, employee.getDesignation());
        statement.setDouble(4, employee.getSalary());
        statement.setInt(5, employee.getId());

        statement.executeUpdate();
        statement.close();
        disconnect();
    }

    public void deleteEmployee(int id) throws SQLException {
        String sql = "DELETE FROM employee WHERE id = ?";
        connect();

        PreparedStatement statement = jdbcConnection.prepareStatement(sql);
        statement.setInt(1, id);

        statement.executeUpdate();
        statement.close();
        disconnect();
    }
}