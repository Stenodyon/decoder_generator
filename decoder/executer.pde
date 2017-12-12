/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Written by Kevin Le Run (Stenodyon)
*/

import java.awt.Robot;
import java.io.*;

int commandRate = 30;

interface IExecuter
{
    void executeCommand(String command);
    void close();
}

class RobotExecuter implements IExecuter
{
    Robot robot;

    public RobotExecuter()
    {
        try
        {
            robot = new Robot();
            robot.setAutoDelay(commandRate);
        } catch (Exception e)
        {
            e.printStackTrace();
            exit();
        }
        for(int countdown = 5; countdown > 0; countdown--)
        {
            println(countdown + "...");
            delay(1000);
        }
    }

    void executeCommand(String command)
    {
        robot.keyPress('\n');
        robot.keyRelease('\n');
        robot.keyPress('/');
        robot.keyRelease('/');
        typeString(command);
        robot.keyPress('\n');
        robot.keyRelease('\n');
    }

    void typeString(String text)
    {
        robot.setAutoDelay(1);
        for(int i = 0; i < text.length(); i++)
        {
            int c = text.charAt(i);
            if(Character.isUpperCase(c) || c == '~' || c == ':' || c == '_')
            {
                robot.keyPress(java.awt.event.KeyEvent.VK_SHIFT);
            }
            int keyCode = java.awt.event.KeyEvent.getExtendedKeyCodeForChar(c);
            if(c == '~') keyCode = java.awt.event.KeyEvent.VK_BACK_QUOTE;
            robot.keyPress(keyCode);
            robot.keyRelease(keyCode);
            if(Character.isUpperCase(c) || c == '~' || c == ':' || c == '_')
            {
                robot.keyRelease(java.awt.event.KeyEvent.VK_SHIFT);
            }
        }
        robot.setAutoDelay(commandRate);
    }

    void close() {}
}

class FileExecuter implements IExecuter
{
    String filename;
    FileWriter out = null;

    public FileExecuter(String filename)
    {
        this.filename = filename;
        try
        {
            out = new FileWriter(filename);
        } catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    void executeCommand(String command)
    {
        try
        {
            out.write(command + "\n");
        } catch(Exception e)
        {
            e.printStackTrace();
            this.close();
            exit();
        }
    }

    void close()
    {
        try
        {
            out.close();
            println("Output written to " + filename);
        } catch (Exception e)
        {
            e.printStackTrace();
        }
    }
}
