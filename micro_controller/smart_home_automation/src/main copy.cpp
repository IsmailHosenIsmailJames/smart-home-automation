#include <iostream>
#include <string>
#include <vector>

std::vector<std::string> getDataList(std::string data);
int main()
{
    std::string data = "96:0,16:1,96:0,16:1,";
    std::vector<std::string> arrayOfData = getDataList(data);
    int size = arrayOfData.size();
    for (int i = 0; i < arrayOfData.size(); i++)
    {
        std::cout << arrayOfData[0].c_str();
    }
}

std::vector<std::string> getDataList(std::string data)
{
    int size = data.size();
    int countOfComma = 0;
    for (int i = 0; i < size; i++)
    {
        if (data[i] == ',')
        {
            countOfComma++;
        }
    }

    std::vector<std::string> arrayOfData;
    for (int i = 0; i < countOfComma; i++)
    {
        int size = data.size();
        for (int x = 0; x < size; x++)
        {
            if (data[x] == ',')
            {
                arrayOfData.push_back(data.substr(0, x));
                data = data.substr(x + 1);
                break;
            }
        }
    }
    return arrayOfData;
}