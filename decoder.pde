import java.awt.*;
import java.awt.event.*;
import java.awt.datatransfer.*;
import javax.swing.*;
import java.io.*;

Robot robot;

String block = "minecraft:iron_block";
String redstone = "minecraft:redstone_wire";
String repeater = "minecraft:unpowered_repeater";
String torch = "minecraft:redstone_torch";
String air = "minecraft:air";

int commandRate = 30;
int orientation = 0;
/*
0 = south
1 = north
2 = east
3 = west
*/

void setup() {
    try
    {
        robot = new Robot();
        robot.setAutoDelay(commandRate);
    }
    catch (Exception e)
    {
        e.printStackTrace();
    }
    size(600, 400);
    selectInput("Select a file to process:", "fileSelected");
}

void fileSelected(File selection)
{
    String path = null;
    if (selection == null)
    {
        println("Window was closed or the user hit cancel.");
        exit();
    }
    path = selection.getAbsolutePath();
    println(path);
    String[] lines = loadStrings(path);
    parseModules(lines);
    println("File parsed");
    solveModules();
    println("Problems solved");
    for(int countdown = 5; countdown > 0; countdown--)
    {
        println(countdown + "...");
        delay(1000);
    }
    buildOutput();
    buildModules();
    println("Placing repeaters...");
    placeRepeaters();
    println("Done!");
    exit();
}

int[][] modules;

void setOrientation(String input)
{
    if(input.equals("south"))
        orientation = 0;
    else if(input.equals("north"))
        orientation = 1;
    else if(input.equals("east"))
        orientation = 2;
    else if(input.equals("west"))
        orientation = 3;
}

void parseModules(String[] lines)
{
    int width = lines[0].length();
    int height = lines.length;
    String lastLine = lines[lines.length-1].toLowerCase();
    if(lastLine.equals("north") || lastLine.equals("south")
       || lastLine.equals("east") || lastLine.equals("west"))
    {
        height--;
        setOrientation(lastLine);
    }
    modules = new int[height][width];
    for(int lineIndex = 0; lineIndex < height; lineIndex++)
    {
        String line = lines[lineIndex];
        if(line.length() != width)
        {
            println("Parse error: not all lines are of same length");
            exit();
        }
        for(int moduleIndex = 0; moduleIndex < width; moduleIndex++)
        {
            int c = line.charAt(moduleIndex);
            switch(c)
            {
                case '0':
                    modules[height - 1 - lineIndex][width - 1 - moduleIndex] = 2;
                    break;
                case '1':
                    modules[height - 1 - lineIndex][width - 1 - moduleIndex] = 1;
                    break;
                case 'X':
                    modules[height - 1 - lineIndex][width - 1 - moduleIndex] = 0;
                    break;
                default:
                    println("Parse error: unexpected '" + (char)c + "'");
                    exit();
            }
        }
    }
}

void solveModules()
{
    for(int y = modules.length - 1; y > 0; y--)
    {
        for(int x = 0; x < modules[0].length; x++)
        {
            if(modules[y][x] == 2 && modules[y-1][x] == 2)
            {
                modules[y-1][x] = 0;
                modules[y][x] = 3;
            }
        }
    }
    for(int y = modules.length - 1; y > 0; y--)
    {
        for(int x = 0; x < modules[0].length - 1; x++)
        {
            if(modules[y][x] == 3 && modules[y][x+1] == 3)
            {
                modules[y-1][x] = 4;
                modules[y-1][x + 1] = 5;
                modules[y][x] = 6;
                modules[y][x + 1] = 7;
            }
        }
    }
}

void buildOutput()
{
    int length = modules[0].length * 2;
    for(int y = 0; y < modules.length; y++)
    {
        int Y = y * 2 + 2;
        fillBlocks(length + 2, -4, Y + 1, 2, -4, Y + 1, block);
        fillBlocks(length + 2, -3, Y + 1, 2, -3, Y + 1, redstone);
        setBlock(1, -4, Y + 1, torch, 2);
        println("Built output lane " + (y+1) + " of " + modules.length);
    }
}

void buildModule0(int x, int y)
{
    int X = x * 2;
    int Y = y * 2;
    fillBlocks(X, -2, Y, X, -2, Y + 1, block);
    fillBlocks(X, -1, Y, X, -1, Y + 1, redstone);
}

void buildModule1(int x, int y)
{
    fillBlocks(x * 2, -2, y * 2, x * 2, -2, y * 2 + 1, block);
    fillBlocks(x * 2, -1, y * 2, x * 2, -1, y * 2 + 1, redstone);
    setBlock(x * 2 + 1, -2, y * 2 + 1, torch, 1);
}

void buildModule2(int x, int y)
{
    setBlock(x * 2, -2, y * 2 + 1, block);
    setBlock(x * 2, -3, y * 2, block);
    setBlock(x * 2, -2, y * 2, repeater, 2);
    fillBlocks(x * 2, -1, y * 2, x * 2, -1, y * 2 + 1, block);
    fillBlocks(x * 2, 0, y * 2, x * 2, 0, y * 2 + 1, redstone);
}

void buildModule3(int x, int y)
{
    int X = x * 2;
    int Y = y * 2;
    setBlock(X, -2, Y + 1, block);
    setBlock(X, -3, Y, block);
    setBlock(X, -1, Y + 1, redstone);
    setBlock(X, -2, Y, redstone);
    setBlock(X + 1, -4, Y, block);
    setBlock(X + 1, -3, Y, repeater, 1);
    setBlock(X + 2, -3, Y, block);
    setBlock(X + 2, -4, Y - 1, block);
    setBlock(X + 2, -4, Y + 1, block);
    setBlock(X + 2, -3, Y - 1, redstone);
    setBlock(X + 2, -3, Y + 1, redstone);
}

void buildModule4(int x, int y)
{
    int X = x * 2;
    int Y = y * 2;
    setBlock(X, -1, Y, block);
    setBlock(X, 0, Y, redstone);

    fillBlocks(X + 1, -2, Y + 1, X, -2, Y + 1, block);
    fillBlocks(X + 1, -1, Y + 1, X, -1, Y + 1, redstone);

    setBlock(X, 0, Y + 1, block);
    setBlock(X, 1, Y + 1, redstone);
}

void buildModule5(int x, int y)
{
    int X = x * 2;
    int Y = y * 2;
    setBlock(X, -1, Y, block);
    setBlock(X, 0, Y, redstone);

    setBlock(X, -2, Y + 1, block);
    setBlock(X, -1, Y + 1, redstone);

    setBlock(X, 0, Y + 1, block);
    setBlock(X, 1, Y + 1, redstone);
}

void buildModule6(int x, int y)
{
    int X = x * 2;
    int Y = y * 2;
    fillBlocks(X, -3, Y, X, -1, Y, block);
    setBlock(X, -2, Y, repeater, 0);
    setBlock(X, 0, Y, redstone);

    setBlock(X, -2, Y + 1, block);
    setBlock(X, -1, Y + 1, redstone);
    setBlock(X + 1, -3, Y, block);
    setBlock(X + 1, -2, Y, redstone);
}

void buildModule7(int x, int y)
{
    int X = x * 2;
    int Y = y * 2;
    fillBlocks(X, -3, Y, X, -1, Y, block);
    setBlock(X, -2, Y, repeater, 0);
    setBlock(X, 0, Y, redstone);

    setBlock(X, -2, Y + 1, block);
    setBlock(X, -1, Y + 1, redstone);
}

void buildModules()
{
    for(int y = 0; y < modules.length; y++)
    {
        for(int x = 0; x < modules[y].length; x++)
        {
            int module = modules[y][x];
            switch(module)
            {
                case 0:
                    buildModule0(x + 1, y + 1);
                    break;
                case 1:
                    buildModule1(x + 1, y + 1);
                    break;
                case 2:
                    buildModule2(x + 1, y + 1);
                    break;
                case 3:
                    buildModule3(x + 1, y + 1);
                    break;
                case 4:
                    buildModule4(x + 1, y + 1);
                    break;
                case 5:
                    buildModule5(x + 1, y + 1);
                    break;
                case 6:
                    buildModule6(x + 1, y + 1);
                    break;
                case 7:
                    buildModule7(x + 1, y + 1);
                    break;
            }
        }
        println("Built row " + (y + 1) + " of " + modules.length);
    }
    for(int x = 0; x < modules[0].length; x++)
    {
        fillBlocks(x * 2 + 2, -2, 0, x * 2 + 2, -2, 1, block);
        setBlock(x * 2 + 2, -1, 0, repeater, 2);
        setBlock(x * 2 + 2, -1, 1, redstone);
    }
}

void placeRepeaters()
{
    for(int y = 7; y < modules.length; y += 7)
    {
        for(int x = 0; x < modules[y].length; x++)
        {
            int module = modules[y][x];
            if(module == 4 || module == 5) // Those modules are very hard to put a repeater on
            {
                y--;
                break;
            }
        }
        int Y = y * 2 + 2;
        for(int x = 0; x < modules[y].length; x++)
        {
            int X = x * 2 + 2;
            int module = modules[y][x];
            switch(module)
            {
                case 0:
                case 1:
                    setBlock(X, -1, Y, repeater, 2);
                    break;
                case 2:
                    fillBlocks(X, 0, Y, X, -1, Y + 1, air);
                    setBlock(X, -1, Y + 1, redstone);
                    break;
                case 3:
                    setBlock(X, -1, Y - 1, repeater, 2);
                    setBlock(X, -1, Y, block);
                    break;
                case 6:
                case 7:
                    setBlock(X, 0, Y, repeater, 2);
                    setBlock(X, 0, Y + 1, block);
                    break;
            }
        }
    }
    for(int x = 7; x < modules[0].length; x += 7)
    {
        int X = x * 2 + 2;
        for(int y = 0; y < modules.length; y++)
        {
            int Y = y * 2 + 2;
            int module = modules[y][x];
            switch(module)
            {
                case 1:
                case 6:
                    setBlock(X, -3, Y + 1, repeater, 3);
                    break;
                default:
                    setBlock(X + 1, -3, Y + 1, repeater, 3);
                    break;
            }
        }
    }
}

void setBlock(int x, int y, int z, String block)
{
    setBlock(x, y, z, block, 0);
}

int[][] torchDir =
{
    {0, 1, 2, 3, 4},
    {0, 2, 1, 4, 3},
    {0, 4, 3, 1, 2},
    {0, 3, 4, 2, 1}
};

void setBlock(int x, int y, int z, String block, int dir)
{
    boolean isTorch = block.equals(torch);
    if(orientation == 1)
    {
        z = -z;
        x = -x;
        if(!isTorch)
            dir = (dir + 2) % 4;
    }
    else if(orientation == 2)
    {
        int temp = x;
        x = z;
        z = -temp;
        if(!isTorch)
            dir = (dir + 3) % 4;
    }
    else if(orientation == 3)
    {
        int temp = x;
        x = -z;
        z = temp;
        if(!isTorch)
            dir = (dir + 1) % 4;
    }
    if(isTorch)
        dir = torchDir[orientation][dir];
    executeCommand("setblock ~" + x + " ~" + y + " ~" + z + " " + block + " " + dir);
}

void fillBlocks(int x1, int y1, int z1, int x2, int y2, int z2, String block)
{
    if(orientation == 1)
    {
        z1 = -z1;
        x1 = -x1;
        z2 = -z2;
        x2 = -x2;
    }
    else if(orientation == 2)
    {
        int temp = x1;
        x1 = z1;
        z1 = -temp;
        temp = x2;
        x2 = z2;
        z2 = -temp;
    }
    else if(orientation == 3)
    {
        int temp = x1;
        x1 = -z1;
        z1 = temp;
        temp = x2;
        x2 = -z2;
        z2 = temp;
    }
    executeCommand("fill ~" + x1 + " ~" + y1 + " ~" + z1
        + " ~" + x2 + " ~" + y2 + " ~" + z2 + " " + block);
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
