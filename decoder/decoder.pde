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

import java.awt.*;
import java.awt.event.*;
import java.awt.datatransfer.*;
import javax.swing.*;
import java.io.*;

String block = "minecraft:iron_block";
String redstone = "minecraft:redstone_wire";
String repeater = "minecraft:unpowered_repeater";
String torch = "minecraft:redstone_torch";
String air = "minecraft:air";

int orientation = 0;
/*
0 = south
1 = north
2 = east
3 = west
*/

IExecuter executer;

void setup()
{
    size(0, 0);
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
    //executer = new FileExecuter("out.txt");
    executer = new RobotExecuter();
    println("Building stated at " + hour() + ":" + minute() + "." + second());
    buildOutput();
    buildModules();
    println("Placing repeaters...");
    placeRepeaters();
    println("Done!");
    println("Building finished at " + hour() + ":" + minute() + "." + second());
    executer.close();
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
                    modules[lineIndex][width - 1 - moduleIndex] = 2;
                    break;
                case '1':
                    modules[lineIndex][width - 1 - moduleIndex] = 1;
                    break;
                case 'X':
                    modules[lineIndex][width - 1 - moduleIndex] = 0;
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

void buildOutputLane(int Y)
{
    int length = modules[0].length * 2;
    fillBlocks(length + 2, -4, Y + 1, 2, -4, Y + 1, block);
    fillBlocks(length + 2, -3, Y + 1, 2, -3, Y + 1, redstone);
    setBlock(1, -4, Y + 1, torch, 2);
}

void copyOutputLanes(int count, int Y)
{
    int length = modules[0].length * 2;
    int depth = count * 2 - 1;
    cloneBlocks(length + 2, -4, 2, 1, -3, 2 + depth, 1, -4, Y);
}

void buildOutput()
{
    buildOutputLane(2);
    int availableLanes = 1;
    int leftToBuild = modules.length - 1;
    int y = 1;
    while(leftToBuild > 0)
    {
        int toCopy = min(availableLanes, leftToBuild);
        copyOutputLanes(toCopy, y * 2 + 2);
        availableLanes += toCopy;
        leftToBuild -= toCopy;
        y += toCopy;
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

void copyModule(int xsrc, int ysrc, int xdest, int ydest)
{
    int Xsrc = xsrc * 2;
    int Ysrc = ysrc * 2;
    int Xdest = xdest * 2;
    int Ydest = ydest * 2;
    cloneBlocks(Xsrc, -4, Ysrc,
                Xsrc + 1, 1, Ysrc + 1,
                Xdest, -4, Ydest);
}

void copyModuleLine(int xsrc, int ysrc, int count, int xdest, int ydest)
{
    int Xsrc = xsrc * 2;
    int Ysrc = ysrc * 2;
    int Xdest = xdest * 2;
    int Ydest = ydest * 2;
    cloneBlocks(Xsrc, -4, Ysrc,
                Xsrc + 2 * count + 1, 1, Ysrc + 1,
                Xdest, -4, Ydest);
}

int[] moduleLocationX;
int[] moduleLocationY;

void buildInput()
{
    fillBlocks(2, -2, 0, 2, -2, 1, block);
    setBlock(2, -1, 0, repeater, 2);
    setBlock(2, -1, 1, redstone);
    int availableLanes = 1;
    int leftToBuild = modules[0].length - 1;
    int x = 1;
    while(leftToBuild > 0)
    {
        int toCopy = min(availableLanes, leftToBuild);
        int depth = toCopy * 2 - 1;
        cloneBlocks(2, -2, 0, 2 + depth, -1, 1, x * 2 + 2, -2, 0);
        availableLanes += toCopy;
        leftToBuild -= toCopy;
        x += toCopy;
    }
}

void buildModules()
{
    moduleLocationX = new int[8];
    moduleLocationY = new int[8];
    for(int y = 0; y < modules.length; y++)
    {
        for(int x = 0; x < modules[y].length; x++)
        {
            int besty = 0;
            int bestcount = 0;
            for(int py = y - 1; py >= 0; py--)
            {
                if(modules[y][x] == modules[py][x])
                {
                    int px = x;
                    for(; px < modules[y].length && modules[y][px] == modules[py][px]; px++);
                    int count = px - x - 1;
                    if(count > bestcount)
                    {
                        bestcount = count;
                        besty = py;
                    }
                }
            }
            if(bestcount > 1)
            {
                copyModuleLine(x + 1, besty + 1, bestcount,
                               x + 1, y + 1);
                x += bestcount;
                if(x >= modules[y].length)
                    break;
            }

            int module = modules[y][x];
            switch(module)
            {
                case 0:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule0(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
                case 1:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule1(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
                case 2:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule2(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
                case 3:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                    {
                        buildModule3(x + 1, y + 1);
                    }
                    else
                    {
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                        setBlock(x * 2 + 4, -3, y * 2 + 2, block);
                    }
                    break;
                case 4:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule4(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
                case 5:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule5(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
                case 6:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule6(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
                case 7:
                    if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
                        buildModule7(x + 1, y + 1);
                    else
                        copyModule(moduleLocationX[module], moduleLocationY[module],
                                   x + 1, y + 1);
                    break;
            }
            if(moduleLocationX[module] == 0 && moduleLocationY[module] == 0)
            {
                moduleLocationX[module] = x + 1;
                moduleLocationY[module] = y + 1;
            }
        }
        println("Built row " + (y + 1) + " of " + modules.length);
    }
    buildInput();
}

void placeRepeaters()
{
    // Input Lanes
    for(int x = 0; x < modules[0].length; x++)
    {
        int X = x * 2 + 2;
        for(int y = 7; y < modules.length; y += 7)
        {
            int module = modules[y][x];
            if(module == 4 || module == 5)
                y--;
            module = modules[y][x];
            int Y = y * 2 + 2;
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
    // Output Lanes
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
    executer.executeCommand("setblock ~" + x + " ~" + y + " ~" + z + " " + block + " " + dir);
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
    executer.executeCommand("fill ~" + x1 + " ~" + y1 + " ~" + z1
        + " ~" + x2 + " ~" + y2 + " ~" + z2 + " " + block);
}

void cloneBlocks(int x1, int y1, int z1, int x2, int y2, int z2, int x, int y, int z)
{
    int width = abs(x2 - x1);
    int height = abs(z2 - z1);
    if(orientation == 1)
    {
        z1 = -z1;
        x1 = -x1;
        z2 = -z2;
        x2 = -x2;
        z = -z - height;
        x = -x - width;
    }
    else if(orientation == 2)
    {
        int temp = x1;
        x1 = z1;
        z1 = -temp;
        temp = x2;
        x2 = z2;
        z2 = -temp;
        temp = x;
        x = z;
        z = -temp - width;
    }
    else if(orientation == 3)
    {
        int temp = x1;
        x1 = -z1;
        z1 = temp;
        temp = x2;
        x2 = -z2;
        z2 = temp;
        temp = x;
        x = -z - height;
        z = temp;
    }
    executer.executeCommand("clone ~" + x1 + " ~" + y1 + " ~" + z1
        + " ~" + x2 + " ~" + y2 + " ~" + z2
        + " ~" + x  + " ~" + y  + " ~" + z + " masked");
}

